<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TestHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'test_session_id',
        'test_type',
        'result_code',
        'answers',
        'questions',
        'scores',
        'result_payload',
        'package_id',
        'package_name',
    ];

    protected $casts = [
        'answers' => 'array',
        'questions' => 'array',
        'scores' => 'array',
        'result_payload' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function package()
    {
        return $this->belongsTo(ServicePackage::class, 'package_id');
    }
}