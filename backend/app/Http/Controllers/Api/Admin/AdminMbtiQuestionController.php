<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MbtiQuestion;
use Illuminate\Http\Request;

class AdminMbtiQuestionController extends Controller
{
    public function index(Request $request)
    {
        $perPage = (int) $request->get('per_page', 10);
        $axis = $request->get('axis', 'all');
        $packageType = $request->get('package_type', 'all');

        $query = MbtiQuestion::query()->latest('id');

        if ($axis !== 'all') {
            $query->where('axis', $axis);
        }

        if ($packageType !== 'all') {
            $query->where('package_type', $packageType);
        }

        $items = $query->paginate($perPage);

        $statsQuery = MbtiQuestion::query();

        if ($packageType !== 'all') {
            $statsQuery->where('package_type', $packageType);
        }

        $stats = [
            'total' => (clone $statsQuery)->count(),
            'EI' => (clone $statsQuery)->where('axis', 'EI')->count(),
            'SN' => (clone $statsQuery)->where('axis', 'SN')->count(),
            'TF' => (clone $statsQuery)->where('axis', 'TF')->count(),
            'JP' => (clone $statsQuery)->where('axis', 'JP')->count(),
        ];

        return response()->json([
            'data' => $items->items(),
            'current_page' => $items->currentPage(),
            'last_page' => $items->lastPage(),
            'per_page' => $items->perPage(),
            'total' => $items->total(),
            'stats' => $stats,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'question' => ['required','string'],
            'option_a' => ['required','string'],
            'option_b' => ['required','string'],
            'axis' => ['required','in:EI,SN,TF,JP'],
            'package_type' => ['required','in:free,plus,premium'],
        ]);

        $payload = [
            'content' => $data['question'],
            'label_a' => $data['option_a'],
            'label_b' => $data['option_b'],
            'axis' => $data['axis'],
            'package_type' => $data['package_type'],
        ];

        switch ($data['axis']) {
            case 'EI':
                $payload['dir_a']='E';
                $payload['dir_b']='I';
                break;
            case 'SN':
                $payload['dir_a']='S';
                $payload['dir_b']='N';
                break;
            case 'TF':
                $payload['dir_a']='T';
                $payload['dir_b']='F';
                break;
            case 'JP':
                $payload['dir_a']='J';
                $payload['dir_b']='P';
                break;
        }

        $payload['order'] = (MbtiQuestion::max('order') ?? 0) + 1;

        $item = MbtiQuestion::create($payload);

        return response()->json([
            'message'=>'Tạo câu hỏi thành công',
            'data'=>$item
        ],201);
    }

    public function update(Request $request,$id)
    {
        $item = MbtiQuestion::findOrFail($id);

        $data = $request->validate([
            'question'=>['required','string'],
            'option_a'=>['required','string'],
            'option_b'=>['required','string'],
            'axis'=>['required','in:EI,SN,TF,JP'],
            'package_type'=>['required','in:free,plus,premium'],
        ]);

        $payload = [
            'content'=>$data['question'],
            'label_a'=>$data['option_a'],
            'label_b'=>$data['option_b'],
            'axis'=>$data['axis'],
            'package_type'=>$data['package_type'],
        ];

        switch ($data['axis']) {
            case 'EI':
                $payload['dir_a']='E';
                $payload['dir_b']='I';
                break;
            case 'SN':
                $payload['dir_a']='S';
                $payload['dir_b']='N';
                break;
            case 'TF':
                $payload['dir_a']='T';
                $payload['dir_b']='F';
                break;
            case 'JP':
                $payload['dir_a']='J';
                $payload['dir_b']='P';
                break;
        }

        $item->update($payload);

        return response()->json([
            'message'=>'Cập nhật thành công',
            'data'=>$item
        ]);
    }

    public function destroy($id)
    {
        $item = MbtiQuestion::findOrFail($id);
        $item->delete();

        return response()->json([
            'message' => 'Xóa câu hỏi thành công.',
        ]);
    }
}