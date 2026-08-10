<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CoursePayment extends Model
{
    protected $fillable = [
        'user_id',
        'course_id',
        'amount',
        'status',
        'payment_method',
    ];
}