<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;

/**
 * Item photos live on a private disk under item-images/<donor id>/ and are
 * shown through signed URLs that expire (config shareloop.photos).
 */
class PhotoStorage
{
    private static function disk()
    {
        return Storage::disk(config('shareloop.photos.disk'));
    }

    /** Stores [file] in [userId]'s folder and returns its path. */
    public static function store(UploadedFile $file, string $userId): string
    {
        $extension = match ($file->getMimeType()) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };
        $folder = config('shareloop.photos.folder').'/'.$userId;
        $name = Str::lower(Str::random(32)).'.'.$extension;
        self::disk()->putFileAs($folder, $file, $name);

        return $folder.'/'.$name;
    }

    /** @param list<string> $paths */
    public static function delete(array $paths): void
    {
        $safe = array_values(array_filter($paths, [self::class, 'isValidPath']));
        if ($safe !== []) {
            self::disk()->delete($safe);
        }
    }

    public static function isValidPath(string $path): bool
    {
        $folder = preg_quote(config('shareloop.photos.folder'), '#');

        return (bool) preg_match('#^'.$folder.'/[A-Za-z0-9-]+/[a-z0-9]+\.(jpg|png|webp)$#', $path);
    }

    public static function url(string $path): string
    {
        return URL::temporarySignedRoute(
            'photos.show',
            now()->addMinutes(config('shareloop.photos.url_lifetime_minutes')),
            ['path' => $path],
        );
    }

    public static function exists(string $path): bool
    {
        return self::isValidPath($path) && self::disk()->exists($path);
    }

    public static function absolutePath(string $path): string
    {
        return self::disk()->path($path);
    }
}
