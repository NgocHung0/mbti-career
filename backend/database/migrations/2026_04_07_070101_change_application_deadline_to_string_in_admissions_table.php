<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('admissions', function (Blueprint $table) {
            // Dùng ->change() của Laravel để tương thích với mọi Database (MySQL, PostgreSQL, SQLite)
            $table->string('application_deadline')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('admissions', function (Blueprint $table) {
            $table->date('application_deadline')->nullable()->change();
        });
    }
};