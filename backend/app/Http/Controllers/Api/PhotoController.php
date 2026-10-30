<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PhotoStorage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/** Serves an item photo for a valid, unexpired signed URL. */
class PhotoController extends Controller
{
    public function show(string $path): BinaryFileResponse
    {
        if (! PhotoStorage::exists($path)) {
            abort(404, 'Photo not found.');
        }

        return response()->file(PhotoStorage::absolutePath($path), [
            'Cache-Control' => 'private, max-age=3600',
        ]);
    }
}
