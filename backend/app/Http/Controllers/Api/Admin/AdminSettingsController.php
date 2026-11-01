<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSettingsController extends Controller
{
    public function index(): JsonResponse
    {
        $settings = SystemSetting::with('updater:id,display_name')
            ->orderBy('group')
            ->get()
            ->groupBy('group');

        return response()->json($settings);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'settings' => ['required', 'array'],
        ]);

        $userId = $request->user()->id;
        $updatedKeys = [];

        foreach ($data['settings'] as $key => $val) {
            $existing = SystemSetting::find($key);
            $oldVal = $existing?->value;

            if ($existing) {
                $existing->value = is_bool($val) ? ($val ? '1' : '0') : (string) $val;
                $existing->updated_by = $userId;
                $existing->save();
            } else {
                SystemSetting::set($key, $val, 'general', $userId);
            }

            $updatedKeys[$key] = ['old' => $oldVal, 'new' => $val];
        }

        AuditLogger::log(
            action: 'settings.update',
            newValues: $updatedKeys,
            description: 'Updated system configuration parameters'
        );

        return response()->json([
            'message' => 'Settings saved successfully.',
            'settings' => SystemSetting::all()->groupBy('group'),
        ]);
    }

    public function toggleMaintenance(Request $request): JsonResponse
    {
        $current = SystemSetting::get('maintenance_mode', false);
        $new = ! $current;

        SystemSetting::set('maintenance_mode', $new, 'general', $request->user()->id);

        AuditLogger::log(
            action: 'settings.maintenance_mode',
            oldValues: ['maintenance_mode' => $current],
            newValues: ['maintenance_mode' => $new],
            description: 'Toggled system maintenance mode to: ' . ($new ? 'ENABLED' : 'DISABLED')
        );

        return response()->json([
            'message' => 'Maintenance mode is now ' . ($new ? 'ENABLED' : 'DISABLED'),
            'maintenance_mode' => $new,
        ]);
    }
}
