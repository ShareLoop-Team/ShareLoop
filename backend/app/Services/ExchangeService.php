<?php

namespace App\Services;

use App\Models\Exchange;
use App\Models\Item;
use App\Models\ItemRequest;
use App\Models\Rating;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * The handover workflow. These are the only places items, requests and
 * exchanges change state, each in one transaction with the rows locked.
 *
 * Item:     active -> pending_handover -> completed (back to active on cancel)
 * Request:  pending -> approved | rejected
 * Exchange: pending -> completed (both parties confirmed) | cancelled
 */
class ExchangeService
{
    /** The donor picks one pending request for their item; contacts are shared from now on. */
    public function selectRequester(User $me, string $requestId): Exchange
    {
        return DB::transaction(function () use ($me, $requestId) {
            $request = ItemRequest::query()->lockForUpdate()->find($requestId);
            if ($request === null || $request->item_id === null) {
                abort(404, 'Request not found.');
            }
            $item = Item::query()->lockForUpdate()->findOrFail($request->item_id);
            if ($item->donor_id !== $me->id) {
                abort(403, 'Only the donor can select a requester.');
            }
            if ($item->status !== Item::STATUS_ACTIVE || $item->is_hidden) {
                abort(409, 'This item is no longer available.');
            }
            if ($request->status !== ItemRequest::STATUS_PENDING) {
                abort(409, 'This request is no longer pending.');
            }

            $request->forceFill(['status' => ItemRequest::STATUS_APPROVED])->save();
            $item->forceFill([
                'status' => Item::STATUS_PENDING_HANDOVER,
                'selected_request_id' => $request->id,
            ])->save();

            return Exchange::create([
                'item_id' => $item->id,
                'request_id' => $request->id,
                'item_title' => $item->title,
                'donor_id' => $item->donor_id,
                'requester_id' => $request->requester_id,
            ]);
        });
    }

    /** Each party confirms; completes when both have. Confirming twice is a no-op. */
    public function confirmHandover(User $me, string $itemId): Exchange
    {
        return DB::transaction(function () use ($me, $itemId) {
            $exchange = $this->pendingExchange($itemId);

            if ($me->id === $exchange->donor_id) {
                $exchange->donor_confirmed_at ??= now();
            } elseif ($me->id === $exchange->requester_id) {
                $exchange->requester_confirmed_at ??= now();
            } else {
                abort(403, 'You are not part of this exchange.');
            }

            if ($exchange->donor_confirmed_at !== null && $exchange->requester_confirmed_at !== null) {
                $exchange->status = Exchange::STATUS_COMPLETED;
                $exchange->completed_at = now();

                Item::query()->whereKey($exchange->item_id)
                    ->update(['status' => Item::STATUS_COMPLETED, 'updated_at' => now()]);
                User::query()->whereKey($exchange->donor_id)->increment('donation_count');
                // Everyone else who asked for the item gets a definite answer.
                ItemRequest::query()
                    ->where('item_id', $exchange->item_id)
                    ->where('status', ItemRequest::STATUS_PENDING)
                    ->update(['status' => ItemRequest::STATUS_REJECTED, 'updated_at' => now()]);
            }
            $exchange->save();

            return $exchange;
        });
    }

    /** Either party backs out before completion: the item goes back on offer. */
    public function cancel(User $me, string $itemId): Exchange
    {
        return DB::transaction(function () use ($me, $itemId) {
            $exchange = $this->pendingExchange($itemId);
            if (! $exchange->involves($me)) {
                abort(403, 'You are not part of this exchange.');
            }

            $exchange->forceFill([
                'status' => Exchange::STATUS_CANCELLED,
                'cancelled_at' => now(),
                'cancelled_by' => $me->id,
            ])->save();
            Item::query()->whereKey($exchange->item_id)->update([
                'status' => Item::STATUS_ACTIVE,
                'selected_request_id' => null,
                'updated_at' => now(),
            ]);
            if ($exchange->request_id !== null) {
                ItemRequest::query()->whereKey($exchange->request_id)
                    ->update(['status' => ItemRequest::STATUS_REJECTED, 'updated_at' => now()]);
            }
            // Ratings only stand for handovers that actually happened.
            $rateeIds = Rating::query()->where('exchange_id', $exchange->id)->pluck('ratee_id');
            Rating::query()->where('exchange_id', $exchange->id)->delete();
            User::query()->whereIn('id', $rateeIds)->get()->each->refreshRatingSummary();

            return $exchange;
        });
    }

    /** Rate the other party once you have confirmed. The ratee is derived here. */
    public function rate(User $me, string $itemId, int $stars, string $comment): Rating
    {
        return DB::transaction(function () use ($me, $itemId, $stars, $comment) {
            $exchange = Exchange::query()
                ->where('item_id', $itemId)
                ->where('status', '!=', Exchange::STATUS_CANCELLED)
                ->latest()
                ->first();
            if ($exchange === null) {
                abort(404, 'No handover found for this item.');
            }

            if ($me->id === $exchange->donor_id && $exchange->donor_confirmed_at !== null) {
                $rateeId = $exchange->requester_id;
            } elseif ($me->id === $exchange->requester_id && $exchange->requester_confirmed_at !== null) {
                $rateeId = $exchange->donor_id;
            } else {
                abort(403, 'Confirm the handover before rating.');
            }

            $already = Rating::query()
                ->where('exchange_id', $exchange->id)
                ->where('rater_id', $me->id)
                ->exists();
            if ($already) {
                abort(409, 'You have already rated this exchange.');
            }

            $rating = Rating::create([
                'exchange_id' => $exchange->id,
                'item_id' => $exchange->item_id,
                'rater_id' => $me->id,
                'ratee_id' => $rateeId,
                'stars' => $stars,
                'comment' => trim($comment),
            ]);
            User::query()->findOrFail($rateeId)->refreshRatingSummary();

            return $rating;
        });
    }

    private function pendingExchange(string $itemId): Exchange
    {
        $exchange = Exchange::query()
            ->where('item_id', $itemId)
            ->where('status', Exchange::STATUS_PENDING)
            ->lockForUpdate()
            ->first();
        if ($exchange === null) {
            abort(404, 'No handover in progress for this item.');
        }

        return $exchange;
    }
}
