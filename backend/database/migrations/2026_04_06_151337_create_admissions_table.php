<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admissions', function (Blueprint $table) {
            $table->id();

            $table->string('school_name');
            $table->string('major_name');
            $table->string('city')->nullable();
            $table->text('short_description')->nullable();
            $table->string('image_url')->nullable();

            $table->json('tags')->nullable();

            $table->string('status')->default('coming_soon'); // coming_soon | open | closed
            $table->boolean('featured')->default(false);

            $table->string('tuition_fee')->nullable();
            $table->string('duration')->nullable();
            $table->string('degree')->nullable();
            $table->string('admission_method')->nullable();

            $table->date('application_deadline')->nullable();
            $table->date('start_date')->nullable();

            $table->string('register_link')->nullable();
            $table->string('contact_phone')->nullable();
            $table->string('contact_email')->nullable();

            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admissions');
    }
};