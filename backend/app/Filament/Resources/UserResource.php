<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationGroup = 'User Management';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('name')->required(),
            Forms\Components\TextInput::make('email')->email()->required(),
            Forms\Components\TextInput::make('phone'),
            Forms\Components\Select::make('role')
                ->options(['customer' => 'Customer', 'host' => 'Host', 'admin' => 'Admin'])
                ->required(),
            Forms\Components\Select::make('kyc_status')
                ->options(['none' => 'None', 'pending' => 'Pending', 'in_review' => 'In Review', 'approved' => 'Approved', 'rejected' => 'Rejected']),
            Forms\Components\Toggle::make('is_suspended'),
            Forms\Components\Textarea::make('suspension_reason'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('email')->searchable(),
                Tables\Columns\TextColumn::make('phone')->searchable(),
                Tables\Columns\BadgeColumn::make('role')
                    ->colors(['primary' => 'customer', 'success' => 'host', 'danger' => 'admin']),
                Tables\Columns\BadgeColumn::make('kyc_status')
                    ->colors(['gray' => 'none', 'warning' => 'pending', 'info' => 'in_review', 'success' => 'approved', 'danger' => 'rejected']),
                Tables\Columns\TextColumn::make('average_rating')->sortable(),
                Tables\Columns\TextColumn::make('total_trips')->sortable(),
                Tables\Columns\IconColumn::make('is_suspended')->boolean(),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->options(['customer' => 'Customer', 'host' => 'Host', 'admin' => 'Admin']),
                Tables\Filters\SelectFilter::make('kyc_status')
                    ->options(['none' => 'None', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected']),
                Tables\Filters\TernaryFilter::make('is_suspended'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\ViewAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
