<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table(
            'majors',
            function (Blueprint $table) {
                if (
                    !Schema::hasColumn(
                        'majors',
                        'interest_profile'
                    )
                ) {
                    $table
                        ->json('interest_profile')
                        ->nullable()
                        ->after('suitable_mbti');
                }

                if (
                    !Schema::hasColumn(
                        'majors',
                        'ability_profile'
                    )
                ) {
                    $table
                        ->json('ability_profile')
                        ->nullable()
                        ->after('interest_profile');
                }
            }
        );
    }

    public function down(): void
    {
        Schema::table(
            'majors',
            function (Blueprint $table) {
                if (
                    Schema::hasColumn(
                        'majors',
                        'ability_profile'
                    )
                ) {
                    $table->dropColumn(
                        'ability_profile'
                    );
                }

                if (
                    Schema::hasColumn(
                        'majors',
                        'interest_profile'
                    )
                ) {
                    $table->dropColumn(
                        'interest_profile'
                    );
                }
            }
        );
    }
};