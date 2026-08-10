<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up(): void
{
    Schema::table('about_settings', function (Blueprint $table) {
        $table->longText('privacy_policy')->nullable()->after('vision_description');
    });
}

public function down(): void
{
    Schema::table('about_settings', function (Blueprint $table) {
        $table->dropColumn('privacy_policy');
    });
}
};
