<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MbtiProfile extends Model
{
    protected $fillable = [
        'code',
        'name',
        'description'
    ];
}
