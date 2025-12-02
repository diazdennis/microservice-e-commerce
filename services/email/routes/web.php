<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return ['message' => 'Email Service API', 'version' => '1.0.0'];
});
