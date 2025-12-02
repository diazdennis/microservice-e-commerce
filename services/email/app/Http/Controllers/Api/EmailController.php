<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmailLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class EmailController extends Controller
{
    /**
     * Send order confirmation email.
     */
    public function sendOrderConfirmation(Request $request)
    {
        $request->validate([
            'order_id' => 'required|integer',
            'customer_email' => 'required|email',
            'order_data' => 'required|array',
        ]);

        $orderId = $request->order_id;
        $customerEmail = $request->customer_email;
        $orderData = $request->order_data;

        try {
            // 1. Create email log entry
            $emailLog = EmailLog::create([
                'order_id' => $orderId,
                'recipient_email' => $customerEmail,
                'subject' => "Order Confirmation #{$orderId}",
                'status' => 'pending',
            ]);

            // 2. Send email
            $fromAddress = config('mail.from.address', 'noreply@example.com');
            $fromName = config('mail.from.name', 'E-Commerce Store');
            
            Mail::send('emails.order-confirmation', [
                'order' => $orderData,
                'customerEmail' => $customerEmail,
            ], function ($message) use ($customerEmail, $orderId, $fromAddress, $fromName) {
                $message->from($fromAddress, $fromName)
                        ->to($customerEmail)
                        ->subject("Order Confirmation #{$orderId}");
            });

            // 3. Update log as sent
            $emailLog->update([
                'status' => 'sent',
                'sent_at' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Order confirmation email sent successfully',
                'email_log_id' => $emailLog->id,
            ]);

        } catch (\Exception $e) {
            // Update log as failed
            $emailLog->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'EMAIL_FAILED',
                    'message' => 'Failed to send order confirmation email',
                    'details' => $e->getMessage(),
                ]
            ], 500);
        }
    }

    /**
     * Display a listing of email logs.
     */
    public function index(Request $request)
    {
        $query = EmailLog::query();

        // Apply filters
        if ($request->has('status')) {
            $query->byStatus($request->status);
        }

        if ($request->has('order_id')) {
            $query->byOrder($request->order_id);
        }

        $logs = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $logs,
            'message' => 'Email logs retrieved successfully'
        ]);
    }
}
