<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
class InterestTagSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
    $tags = [
        'Lập trình',
        'Thiết kế',
        'Kinh doanh',
        'Tâm lý – tư vấn',
        'Y tế – sức khỏe',
        'Sư phạm – giáo dục',
        'Truyền thông – marketing',
        'Luật – xã hội',
        'Tài chính – kế toán',
        'Kỹ thuật – máy móc',
    ];

    foreach ($tags as $name) {
        DB::table('interest_tags')->updateOrInsert(
        ['name' => $name],
        ['slug' => Str::slug($name), 'created_at' => now(), 'updated_at' => now()]
        );
    }
    }
}
