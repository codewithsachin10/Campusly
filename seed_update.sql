INSERT INTO app_releases (
    id, version, build_number, title, description, priority, channel,
    minimum_supported_version, status, is_published, published_at, download_url, file_size_bytes
) VALUES (
    gen_random_uuid(), '2.0.0', 20, 'Campusly 2.0.0: The Big Rewrite',
    'We rewrote the app to be faster, lighter, and better!',
    'RECOMMENDED', 'STABLE', '1.0.0', 'PUBLISHED', true, now(),
    'https://github.com/campusly/releases/download/v2.0.0/app-release.apk', 25000000
) RETURNING id;
