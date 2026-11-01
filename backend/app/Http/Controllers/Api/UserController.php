<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\RatingResource;
use App\Http\Resources\UserResource;
use App\Models\Rating;
use App\Models\User;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Public profiles (contact details only where allowed). */
class UserController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $users = User::query()
            ->latest()
            ->limit(config('shareloop.admin_list_limit'))
            ->get();

        return UserResource::collection($users);
    }

    public function show(string $id): UserResource
    {
        return new UserResource(User::query()->findOrFail($id));
    }

    public function ratings(string $id): AnonymousResourceCollection
    {
        $ratings = Rating::query()
            ->where('ratee_id', $id)
            ->latest()
            ->limit(100)
            ->get();

        return RatingResource::collection($ratings);
    }

    public function notifications(\Illuminate\Http\Request $request): \Illuminate\Http\JsonResponse
    {
        $user = $request->user();
        $isDonor = $user->donation_count > 0;
        $isRequester = $user->itemRequests()->exists();

        $notifications = \App\Models\AdminNotification::query()
            ->where(function ($q) use ($user, $isDonor, $isRequester) {
                $q->where('target_type', 'all');
                if ($isDonor) {
                    $q->orWhere('target_type', 'donors');
                }
                if ($isRequester) {
                    $q->orWhere('target_type', 'requesters');
                }
                $q->orWhereJsonContains('target_user_ids', $user->id);
            })
            ->whereIn('channel', ['in_app', 'all'])
            ->latest()
            ->limit(30)
            ->get();

        return response()->json(['data' => $notifications]);
    }
}
