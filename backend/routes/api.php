<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MajorController;
use App\Http\Controllers\Api\MbtiResultController;
use App\Http\Controllers\Api\InterestResultController;
use App\Http\Controllers\Api\AbilityResultController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\AdminMajorAiController;
use App\Http\Controllers\Api\AdmissionController;
use App\Http\Controllers\Api\Admin\PackageAdminController;
use App\Http\Controllers\Api\Admin\CourseAdminController;
use App\Http\Controllers\Api\Admin\CourseLessonController;
use App\Http\Controllers\Api\Admin\LessonQuizController;
use App\Http\Controllers\Api\Admin\AboutSettingController;
use App\Http\Controllers\Api\CoursePublicController;
use App\Http\Controllers\Api\CoursePaymentController;
use App\Http\Controllers\Api\CoursePublicLessonController;
use App\Http\Controllers\Api\PackageLessonPublicController;
use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\UserPortalController;
use App\Http\Controllers\Api\MbtiPaymentController;
use App\Http\Controllers\Api\MbtiController;
use App\Http\Controllers\Api\Admin\AdminMbtiQuestionController;
use App\Http\Controllers\Api\MbtiQuestionController;
use App\Http\Controllers\Api\InterestQuestionController;
use App\Http\Controllers\Api\Admin\MbtiProfileController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\CourseProgressController;
use App\Http\Controllers\Api\CourseQuizHistoryController;
use App\Http\Controllers\Api\AiAnalysisController;







Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/mbti/submit', [MbtiController::class, 'submit']);
Route::get('/mbti/questions', [MbtiQuestionController::class, 'index']);

Route::get('/package-lessons', [PackageLessonPublicController::class, 'index']);

Route::get('/majors', [MajorController::class, 'publicList']);
Route::get('/majors/{id}', [MajorController::class, 'show']);

Route::get('/admissions', [AdmissionController::class, 'publicList']);
Route::get('/admissions/{id}', [AdmissionController::class, 'show']);

Route::middleware('auth:sanctum')->post('/course-payments/confirm', [CoursePaymentController::class, 'confirm']);

Route::get('/admin/dashboard', [AdminDashboardController::class, 'index']);

Route::get('/admin/users', [AdminUserController::class, 'index']);
Route::post('/admin/users', [AdminUserController::class, 'store']);
Route::put('/admin/users/{user}', [AdminUserController::class, 'update']);
Route::delete('/admin/users/{user}', [AdminUserController::class, 'destroy']);

Route::prefix('admin/mbti')->group(function () {
    Route::get('/questions', [AdminMbtiQuestionController::class, 'index']);
    Route::post('/questions', [AdminMbtiQuestionController::class, 'store']);
    Route::put('/questions/{id}', [AdminMbtiQuestionController::class, 'update']);
    Route::delete('/questions/{id}', [AdminMbtiQuestionController::class, 'destroy']);
});
 Route::get('/mbti-profiles/{code}', [MbtiProfileController::class, 'showByCode']);
Route::prefix('admin')->group(function () {

    Route::get('/mbti', [MbtiProfileController::class, 'index']);
    Route::post('/mbti', [MbtiProfileController::class, 'store']);
    Route::put('/mbti/{id}', [MbtiProfileController::class, 'update']);
    Route::delete('/mbti/{id}', [MbtiProfileController::class, 'destroy']);
   
});
Route::get('/interest/questions', [InterestQuestionController::class, 'index']);
Route::get('/admin/majors', [MajorController::class, 'index']);
Route::post('/admin/majors', [MajorController::class, 'store']);
Route::put('/admin/majors/{id}', [MajorController::class, 'update']);
Route::delete('/admin/majors/{id}', [MajorController::class, 'destroy']);

Route::get('/admin/courses', [CourseAdminController::class, 'index']);
Route::post('/admin/courses', [CourseAdminController::class, 'store']);
Route::put('/admin/courses/{id}', [CourseAdminController::class, 'update']);
Route::delete('/admin/courses/{id}', [CourseAdminController::class, 'destroy']);

Route::get('/admin/courses/{course}/lessons', [CourseLessonController::class, 'index']);
Route::post('/admin/courses/{course}/lessons', [CourseLessonController::class, 'store']);
Route::put('/admin/courses/{course}/lessons/{lesson}', [CourseLessonController::class, 'update']);
Route::delete('/admin/courses/{course}/lessons/{lesson}', [CourseLessonController::class, 'destroy']);

Route::get('/admin/lessons/{lesson}/quizzes', [LessonQuizController::class, 'index']);
Route::post('/admin/lessons/{lesson}/quizzes', [LessonQuizController::class, 'store']);
Route::put('/admin/lessons/{lesson}/quizzes/{quiz}', [LessonQuizController::class, 'update']);
Route::delete('/admin/lessons/{lesson}/quizzes/{quiz}', [LessonQuizController::class, 'destroy']);

Route::get('/settings/about', [AboutSettingController::class, 'show']);
Route::post('/settings/about', [AboutSettingController::class, 'save']);
Route::post('/settings/about/stats', [AboutSettingController::class, 'createStat']);
Route::put('/settings/about/stats/{id}', [AboutSettingController::class, 'updateStat']);
Route::delete('/settings/about/stats/{id}', [AboutSettingController::class, 'deleteStat']);
Route::post('/settings/about/upload', [AboutSettingController::class, 'uploadImage']);

Route::post('/admin/majors/ai-suggest-vector', [AdminMajorAiController::class, 'suggest']);

Route::get('/admin/admissions/majors', [AdmissionController::class, 'majors']);
Route::get('/admin/admissions', [AdmissionController::class, 'index']);
Route::post('/admin/admissions', [AdmissionController::class, 'store']);
Route::put('/admin/admissions/{id}', [AdmissionController::class, 'update']);
Route::post('/admin/admissions/{id}', [AdmissionController::class, 'update']);
Route::delete('/admin/admissions/{id}', [AdmissionController::class, 'destroy']);

Route::get('/admin/packages', [PackageAdminController::class, 'index']);
Route::post('/admin/packages', [PackageAdminController::class, 'store']);
Route::put('/admin/packages/{id}', [PackageAdminController::class, 'update']);
Route::delete('/admin/packages/{id}', [PackageAdminController::class, 'destroy']);

Route::post('/mbti-payments/webhook', [MbtiPaymentController::class, 'webhook']);

Route::match(['get', 'post'], '/recommendations/majors', [RecommendationController::class, 'majors']);

Route::post('/ai/top-abilities', [AiAnalysisController::class, 'topAbilities']);








Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);

    Route::get('/courses', [CoursePublicController::class, 'index']);
    Route::get('/courses/{id}', [CoursePublicController::class, 'show']);
    Route::get('/courses/{course}/lessons', [CoursePublicLessonController::class, 'index']);

    Route::post('/mbti-results', [MbtiResultController::class, 'store']);
    Route::get('/mbti-results/latest', [MbtiResultController::class, 'latest']);
    Route::get('/mbti-results/history', [MbtiResultController::class, 'history']);
    Route::get('/mbti-results', [MbtiResultController::class, 'history']);

    Route::post('/mbti-payment/create', [MbtiPaymentController::class, 'createLink']);
    Route::get('/mbti-payment/status/{orderCode}', [MbtiPaymentController::class, 'status']);

    Route::post('/interest-results', [InterestResultController::class, 'store']);
    Route::get('/interest-results/latest', [InterestResultController::class, 'latest']);

    Route::post('/ability-results', [AbilityResultController::class, 'store']);
    Route::get('/ability-results/latest', [AbilityResultController::class, 'latest']);

    Route::get('/user/service-packages', [UserPortalController::class, 'packages']);
    Route::post('/user/service-packages/assign', [UserPortalController::class, 'assignPackage']);

    Route::get('/user/test-histories', [UserPortalController::class, 'histories']);
    Route::get('/user/test-histories/{id}', [UserPortalController::class, 'historyDetail']);
    Route::post('/user/test-histories', [UserPortalController::class, 'storeHistory']);

    Route::post('/profile/update', [AuthController::class, 'updateProfile']);
    Route::get('/user/packages', [UserPortalController::class, 'packages']);

    Route::get('/course-progress/{lessonId}', [CourseProgressController::class, 'show']);
    Route::post('/course-progress', [CourseProgressController::class, 'save']);
    Route::get('/course-progress-history', [CourseProgressController::class, 'history']);

    Route::get('/course-quiz-history', [CourseQuizHistoryController::class, 'index']);
    Route::get('/course-quiz-history/{lessonId}', [CourseQuizHistoryController::class, 'show']);
    Route::post('/course-quiz-history/answer', [CourseQuizHistoryController::class, 'store']);

    Route::post('/change-password/request-otp', [AuthController::class, 'requestChangePasswordOtp']);
    Route::post('/change-password/verify-otp', [AuthController::class, 'verifyChangePasswordOtp']);

    Route::post('/me/avatar', [AuthController::class, 'updateAvatar']);

    Route::post('/forgot-password/request-otp', [AuthController::class, 'requestForgotPasswordOtp']);
    Route::post('/forgot-password/reset', [AuthController::class, 'resetForgotPassword']);
});