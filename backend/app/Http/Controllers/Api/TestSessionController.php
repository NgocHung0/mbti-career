<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TestSession;
use App\Services\InterestFitService;
use App\Services\MbtiService;
use App\Services\MajorMatchService;
use Illuminate\Http\Request;

class TestSessionController extends Controller
{
    public function create(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 401);
        }

        $v = $request->validate([
            'device_id' => ['required', 'string', 'max:64'],
            'package' => ['nullable', 'string', 'max:20'],
        ]);

        $session = TestSession::create([
            'user_id' => $user->id,
            'device_id' => $v['device_id'],
            'package' => $v['package'] ?? 'basic',
            'status' => 'draft',
            'answers' => [],
            'interest_tags' => [],
        ]);

        return response()->json([
            'id' => $session->id,
            'status' => $session->status,
        ], 201);
    }

    public function submit(Request $request, $id, MbtiService $mbti)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 401);
        }

        $v = $request->validate([
            'device_id' => ['required', 'string', 'max:64'],
            'answers' => ['required', 'array', 'min:1'],
            'answers.*.question_id' => ['required', 'integer'],
            'answers.*.choice' => ['required', 'in:A,B,a,b'],
        ]);

        $normalizedAnswers = collect($v['answers'])
            ->map(function ($answer) {
                return [
                    'question_id' => (int) $answer['question_id'],
                    'choice' => strtoupper($answer['choice']),
                ];
            })
            ->values()
            ->all();

        $session = TestSession::query()
            ->where('id', (int) $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($session->status === 'submitted') {
            return response()->json([
                'message' => 'Session already submitted.',
            ], 409);
        }

        $vector = $mbti->calculateVector($normalizedAnswers);
        $type = $mbti->mbtiTypeFromVector($vector);

        $session->update([
            'device_id' => $v['device_id'],
            'answers' => $normalizedAnswers,
            'vector' => $vector,
            'mbti_type' => $type,
            'status' => 'submitted',
            'submitted_at' => now(),
        ]);

        return response()->json([
            'id' => $session->id,
            'mbti_type' => $type,
            'vector' => $vector,
        ]);
    }

    public function result(Request $request, $id, MajorMatchService $match)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 401);
        }

        $session = TestSession::query()
            ->where('id', (int) $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($session->status !== 'submitted') {
            return response()->json([
                'message' => 'Session not submitted',
            ], 409);
        }

        $topMajors = $match->topMajors(
            $session->vector ?? ['E' => 50, 'S' => 50, 'T' => 50, 'J' => 50],
            50
        );

        $tagIds = $session->interest_tags ?? [];
        $fitInterestMap = [];

        if (is_array($tagIds) && count($tagIds) > 0) {
            $fitInterestMap = app(InterestFitService::class)->calcByTags($tagIds);
        }

        $scored = collect($topMajors)->map(function ($m) use ($fitInterestMap, $tagIds) {
            $fitMbti = (int) ($m['fit'] ?? 0);

            $fitInterest = (is_array($tagIds) && count($tagIds) > 0)
                ? (int) ($fitInterestMap[$m['id']] ?? 0)
                : 0;

            $final = (is_array($tagIds) && count($tagIds) > 0)
                ? round(0.7 * $fitMbti + 0.3 * $fitInterest, 1)
                : $fitMbti;

            $m['fit_mbti'] = $fitMbti;
            $m['fit_interest'] = $fitInterest;
            $m['final'] = $final;
            $m['explain'] = [
                'mbti' => "MBTI phù hợp {$fitMbti}%",
                'interest' => "Sở thích phù hợp {$fitInterest}%",
                'formula' => 'Final = 70% MBTI + 30% Interest',
            ];

            return $m;
        });

        $top3 = $scored
            ->sortByDesc('final')
            ->take(3)
            ->values()
            ->all();

        return response()->json([
            'id' => $session->id,
            'mbti_type' => $session->mbti_type,
            'vector' => $session->vector,
            'interest_tags' => $session->interest_tags ?? [],
            'top_majors' => $top3,
        ]);
    }

    public function submitInterest(Request $request, $id)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'message' => 'Unauthorized',
            ], 401);
        }

        $v = $request->validate([
            'device_id' => ['required', 'string', 'max:64'],
            'tag_ids' => ['required', 'array', 'min:1'],
            'tag_ids.*' => ['integer'],
        ]);

        $session = TestSession::query()
            ->where('id', (int) $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $session->update([
            'device_id' => $v['device_id'],
            'interest_tags' => array_values($v['tag_ids']),
        ]);

        return response()->json([
            'message' => 'Interest tags saved successfully.',
            'interest_tags' => $session->interest_tags,
        ]);
    }
}