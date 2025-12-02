<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $products = [
            // Electronics
            [
                'category_id' => 1,
                'name' => 'Wireless Bluetooth Headphones',
                'description' => 'High-quality wireless headphones with noise cancellation',
                'price' => 79.99,
                'image_url' => 'https://picsum.photos/seed/headphones/400/400',
                'stock' => 50,
            ],
            [
                'category_id' => 1,
                'name' => 'USB-C Fast Charger',
                'description' => '25W fast charger compatible with all USB-C devices',
                'price' => 24.99,
                'image_url' => 'https://picsum.photos/seed/charger/400/400',
                'stock' => 100,
            ],
            [
                'category_id' => 1,
                'name' => 'Phone Stand',
                'description' => 'Adjustable phone stand for desk and car use',
                'price' => 15.99,
                'image_url' => 'https://picsum.photos/seed/stand/400/400',
                'stock' => 75,
            ],

            // Clothing
            [
                'category_id' => 2,
                'name' => 'Cotton T-Shirt',
                'description' => 'Comfortable 100% cotton t-shirt in various colors',
                'price' => 19.99,
                'image_url' => 'https://picsum.photos/seed/tshirt/400/400',
                'stock' => 200,
            ],
            [
                'category_id' => 2,
                'name' => 'Running Shoes',
                'description' => 'Lightweight running shoes with excellent cushioning',
                'price' => 89.99,
                'image_url' => 'https://picsum.photos/seed/shoes/400/400',
                'stock' => 60,
            ],
            [
                'category_id' => 2,
                'name' => 'Denim Jacket',
                'description' => 'Classic denim jacket perfect for any season',
                'price' => 59.99,
                'image_url' => 'https://picsum.photos/seed/jacket/400/400',
                'stock' => 40,
            ],

            // Home & Garden
            [
                'category_id' => 3,
                'name' => 'Plant Pot Set',
                'description' => 'Set of 3 decorative plant pots in modern design',
                'price' => 34.99,
                'image_url' => 'https://picsum.photos/seed/pots/400/400',
                'stock' => 80,
            ],
            [
                'category_id' => 3,
                'name' => 'LED Desk Lamp',
                'description' => 'Adjustable LED desk lamp with USB charging port',
                'price' => 29.99,
                'image_url' => 'https://picsum.photos/seed/lamp/400/400',
                'stock' => 90,
            ],
            [
                'category_id' => 3,
                'name' => 'Kitchen Knife Set',
                'description' => 'Professional 8-piece stainless steel knife set',
                'price' => 49.99,
                'image_url' => 'https://picsum.photos/seed/knives/400/400',
                'stock' => 45,
            ],

            // Books
            [
                'category_id' => 4,
                'name' => 'Programming in PHP',
                'description' => 'Comprehensive guide to PHP programming',
                'price' => 39.99,
                'image_url' => 'https://picsum.photos/seed/phpbook/400/400',
                'stock' => 120,
            ],
            [
                'category_id' => 4,
                'name' => 'Vue.js Guide',
                'description' => 'Complete guide to Vue.js framework',
                'price' => 34.99,
                'image_url' => 'https://picsum.photos/seed/vuebook/400/400',
                'stock' => 100,
            ],
            [
                'category_id' => 4,
                'name' => 'Clean Code',
                'description' => 'A handbook of agile software craftsmanship',
                'price' => 44.99,
                'image_url' => 'https://picsum.photos/seed/cleancode/400/400',
                'stock' => 85,
            ],

            // Sports
            [
                'category_id' => 5,
                'name' => 'Yoga Mat',
                'description' => 'Non-slip yoga mat perfect for all types of exercise',
                'price' => 25.99,
                'image_url' => 'https://picsum.photos/seed/yogamat/400/400',
                'stock' => 150,
            ],
            [
                'category_id' => 5,
                'name' => 'Resistance Bands Set',
                'description' => '5-piece resistance band set for strength training',
                'price' => 19.99,
                'image_url' => 'https://picsum.photos/seed/bands/400/400',
                'stock' => 200,
            ],
            [
                'category_id' => 5,
                'name' => 'Water Bottle 1L',
                'description' => 'Insulated stainless steel water bottle',
                'price' => 14.99,
                'image_url' => 'https://picsum.photos/seed/bottle/400/400',
                'stock' => 180,
            ],
        ];

        foreach ($products as $product) {
            Product::create($product);
        }
    }
}
