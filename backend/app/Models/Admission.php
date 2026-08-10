<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Admission extends Model
{
    protected $table = 'admissions';

    protected $fillable = [
        'school_name',
        'major_name',
        'city',
        'short_description',
        'image_url',
        'tags',
        'status',
        'featured',
        'tuition_fee',
        'duration',
        'degree',
        'admission_method',
        'application_deadline',
        'start_date',
        'register_link',
        'contact_phone',
        'contact_email',
        'sort_order',
        'is_active',
    ];

    protected $casts = [
        'tags' => 'array',
        'featured' => 'boolean',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];

    protected $attributes = [
        'featured' => false,
        'is_active' => true,
        'sort_order' => 0,
        'status' => 'coming_soon',
    ];
}