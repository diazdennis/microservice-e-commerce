<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return ['message' => 'Checkout Service API', 'version' => '1.0.0'];
});
