<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class UserServicePackage extends Model
{
    use HasFactory;

    protected $table = 'user_service_packages';
    
    protected $fillable = [
        'user_id',
        'package_id',
        'status',
        'started_at',
        'expires_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function package()
    {
        return $this->belongsTo(TestPackage::class, 'package_id');
    }
}