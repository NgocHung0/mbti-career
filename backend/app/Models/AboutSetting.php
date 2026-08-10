<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AboutSetting extends Model
{
protected $fillable = [
    'hero_title',
    'short_description',
    'full_description',

    'mission_title',
    'mission_description',

    'vision_title',
    'vision_description',

    'privacy_policy',

    'banner_image',
    'secondary_image',
];
}