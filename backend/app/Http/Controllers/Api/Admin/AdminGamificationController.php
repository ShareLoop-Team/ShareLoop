<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminGamificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::select(['id', 'display_name', 'email', 'points', 'badge', 'trust_score', 'donation_count', 'district']);

        if ($request->filled('badge')) {
            $query->where('badge', $request->input('badge'));
        }

        if ($request->filled('search')) {
            $search = '%' . $request->input('search') . '%';
            $query->where(function ($q) use ($search) {
                $q->where('display_name', 'like', $search)->orWhere('email', 'like', $search);
            });
        }

        $query->orderBy('points', 'desc');
        $perPage = min(100, (int) $request->input('per_page', 15));

        $users = $query->paginate($perPage);

        $badgeStats = [
            'Bronze' => User::where('badge', 'Bronze')->count(),
            'Silver' => User::where('badge', 'Silver')->count(),
            'Gold' => User::where('badge', 'Gold')->count(),
            'Platinum' => User::where('badge', 'Platinum')->count(),
        ];

        return response()->json([
            'users' => $users,
            'badge_distribution' => $badgeStats,
            'badge_rules' => [
                'Bronze' => 'Default tier / 5+ donations',
                'Silver' => '10+ donations / 250+ points',
                'Gold' => '25+ donations / 600+ points',
                'Platinum' => '50+ donations / 1500+ points',
            ],
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $data = $request->validate([
            'badge' => ['nullable', Rule::in(['Bronze', 'Silver', 'Gold', 'Platinum'])],
            'points_delta' => ['nullable', 'integer'],
            'trust_score' => ['nullable', 'integer', 'between:0,100'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $oldValues = [
            'badge' => $user->badge,
            'points' => $user->points,
            'trust_score' => $user->trust_score,
        ];

        if (isset($data['badge'])) {
            $user->badge = $data['badge'];
        }

        if (isset($data['points_delta'])) {
            $user->points = max(0, $user->points + (int) $data['points_delta']);
        }

        if (isset($data['trust_score'])) {
            $user->trust_score = (int) $data['trust_score'];
        }

        $user->save();

        AuditLogger::log(
            action: 'gamification.adjust',
            entity: $user,
            oldValues: $oldValues,
            newValues: [
                'badge' => $user->badge,
                'points' => $user->points,
                'trust_score' => $user->trust_score,
            ],
            description: $data['reason'] ?? 'Gamification points or badge adjustment by admin'
        );

        return response()->json([
            'message' => 'User gamification profile updated.',
            'user' => $user,
        ]);
    }
}
