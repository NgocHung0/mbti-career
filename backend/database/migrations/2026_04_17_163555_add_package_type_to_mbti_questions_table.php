<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('mbti_questions', function (Blueprint $table) {
            $table->string('package_type')->default('free')->after('axis');
        });
    }

    public function down(): void
    {
        Schema::table('mbti_questions', function (Blueprint $table) {
            $table->dropColumn('package_type');
        });
    }
};