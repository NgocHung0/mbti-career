<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('service_packages', function (Blueprint $table) {
            if (!Schema::hasColumn('service_packages', 'course_major')) {
                $table->string('course_major')->nullable()->after('include_ability_test');
            }

            if (!Schema::hasColumn('service_packages', 'course_level')) {
                $table->string('course_level')->nullable()->after('course_major');
            }

            if (!Schema::hasColumn('service_packages', 'thumbnail')) {
                $table->text('thumbnail')->nullable()->after('course_level');
            }

            if (!Schema::hasColumn('service_packages', 'background_image')) {
                $table->text('background_image')->nullable()->after('thumbnail');
            }

            if (!Schema::hasColumn('service_packages', 'preview_video_url')) {
                $table->text('preview_video_url')->nullable()->after('background_image');
            }
        });
    }

    public function down(): void
    {
        Schema::table('service_packages', function (Blueprint $table) {
            $columns = [
                'course_major',
                'course_level',
                'thumbnail',
                'background_image',
                'preview_video_url',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('service_packages', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};