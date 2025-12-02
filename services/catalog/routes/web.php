<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return ['message' => 'Catalog Service API', 'version' => '1.0.0'];
});
