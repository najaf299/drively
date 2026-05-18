<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RoleAndPermissionSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'manage users', 'manage cars', 'manage bookings', 'manage kyc',
            'manage disputes', 'manage promo-codes', 'view dashboard',
            'manage settings', 'manage earnings',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->givePermissionTo($permissions);

        $host = Role::firstOrCreate(['name' => 'host']);
        $host->givePermissionTo(['manage cars', 'manage bookings', 'manage earnings']);

        $customer = Role::firstOrCreate(['name' => 'customer']);
    }
}
