<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Confirmation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #007bff;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #007bff;
            margin: 0;
            font-size: 28px;
        }
        .order-details {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .order-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .order-table th,
        .order-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .order-table th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        .total-row {
            font-weight: bold;
            background-color: #e9ecef;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            color: #666;
        }
        .highlight {
            color: #007bff;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>E-COMMERCE STORE</h1>
            <h2>Order Confirmation #{{ $order['id'] }}</h2>
        </div>

        <p>Hi there!</p>

        <p>Thank you for your order. Here are your order details:</p>

        <div class="order-details">
            <h3>Order Details</h3>
            <p><strong>Order Number:</strong> #{{ $order['id'] }}</p>
            <p><strong>Order Date:</strong> {{ \Carbon\Carbon::parse($order['created_at'])->format('F j, Y') }}</p>
            <p><strong>Email:</strong> {{ $customerEmail }}</p>
        </div>

        <h3>Items Ordered</h3>
        <table class="order-table">
            <thead>
                <tr>
                    <th>Product Name</th>
                    <th>Qty</th>
                    <th>Price</th>
                    <th>Subtotal</th>
                </tr>
            </thead>
            <tbody>
                @php
                    // Handle both snake_case and camelCase from Laravel's toArray()
                    $orderItems = $order['order_items'] ?? $order['orderItems'] ?? [];
                @endphp
                @foreach($orderItems as $item)
                <tr>
                    <td>{{ $item['product_name'] ?? $item['productName'] ?? 'Unknown Product' }}</td>
                    <td>{{ $item['quantity'] ?? 0 }}</td>
                    <td>${{ number_format($item['unit_price'] ?? $item['unitPrice'] ?? 0, 2) }}</td>
                    <td>${{ number_format(($item['quantity'] ?? 0) * ($item['unit_price'] ?? $item['unitPrice'] ?? 0), 2) }}</td>
                </tr>
                @endforeach
                <tr class="total-row">
                    <td colspan="3" style="text-align: right;"><strong>Total:</strong></td>
                    <td><strong>${{ number_format($order['total_amount'], 2) }}</strong></td>
                </tr>
            </tbody>
        </table>

        <div class="footer">
            <p>Thank you for shopping with us!</p>
            <p>If you have any questions, please contact our support team.</p>
        </div>
    </div>
</body>
</html>
