<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('majors', function (Blueprint $table) {
            if (!Schema::hasColumn('majors', 'career_prospects')) {
                $table->text('career_prospects')->nullable()->after('description');
            }

            if (!Schema::hasColumn('majors', 'skills')) {
                $table->text('skills')->nullable()->after('career_prospects');
            }

            if (!Schema::hasColumn('majors', 'top_schools')) {
                $table->json('top_schools')->nullable()->after('skills');
            }

            if (!Schema::hasColumn('majors', 'status')) {
                $table->string('status')->default('active')->after('top_schools');
            }

            if (!Schema::hasColumn('majors', 'vector_e')) {
                $table->integer('vector_e')->default(50)->after('status');
            }

            if (!Schema::hasColumn('majors', 'vector_s')) {
                $table->integer('vector_s')->default(50)->after('vector_e');
            }

            if (!Schema::hasColumn('majors', 'vector_t')) {
                $table->integer('vector_t')->default(50)->after('vector_s');
            }

            if (!Schema::hasColumn('majors', 'vector_j')) {
                $table->integer('vector_j')->default(50)->after('vector_t');
            }
        });
    }

    public function down(): void
    {
        Schema::table('majors', function (Blueprint $table) {
            $columns = [
                'career_prospects',
                'skills',
                'top_schools',
                'status',
                'vector_e',
                'vector_s',
                'vector_t',
                'vector_j',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('majors', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};