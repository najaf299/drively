<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CarResource\Pages;
use App\Models\Car;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CarResource extends Resource
{
    protected static ?string $model = Car::class;
    protected static ?string $navigationIcon = 'heroicon-o-truck';
    protected static ?string $navigationGroup = 'Fleet Management';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Vehicle Info')->schema([
                Forms\Components\TextInput::make('make')->required(),
                Forms\Components\TextInput::make('model')->required(),
                Forms\Components\TextInput::make('year')->numeric()->required(),
                Forms\Components\TextInput::make('trim'),
                Forms\Components\TextInput::make('plate_number')->required(),
                Forms\Components\Select::make('transmission')
                    ->options(['automatic' => 'Automatic', 'manual' => 'Manual'])->required(),
                Forms\Components\Select::make('fuel_type')
                    ->options(['petrol' => 'Petrol', 'diesel' => 'Diesel', 'electric' => 'Electric', 'hybrid' => 'Hybrid'])->required(),
                Forms\Components\TextInput::make('seats')->numeric()->required(),
                Forms\Components\TextInput::make('doors')->numeric()->required(),
            ])->columns(3),
            Forms\Components\Section::make('Pricing')->schema([
                Forms\Components\TextInput::make('daily_price')->numeric()->prefix('$')->required(),
                Forms\Components\TextInput::make('weekly_discount_pct')->numeric()->suffix('%'),
                Forms\Components\TextInput::make('monthly_discount_pct')->numeric()->suffix('%'),
            ])->columns(3),
            Forms\Components\Section::make('Location')->schema([
                Forms\Components\TextInput::make('address'),
                Forms\Components\TextInput::make('city'),
                Forms\Components\TextInput::make('country'),
                Forms\Components\TextInput::make('lat')->numeric(),
                Forms\Components\TextInput::make('lng')->numeric(),
            ])->columns(3),
            Forms\Components\Select::make('status')
                ->options(['draft' => 'Draft', 'pending_approval' => 'Pending Approval', 'active' => 'Active', 'suspended' => 'Suspended', 'deleted' => 'Deleted']),
            Forms\Components\Textarea::make('description'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('make')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('model')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('year')->sortable(),
                Tables\Columns\TextColumn::make('host.name')->label('Host')->searchable(),
                Tables\Columns\TextColumn::make('daily_price')->money('usd')->sortable(),
                Tables\Columns\TextColumn::make('city')->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors(['gray' => 'draft', 'warning' => 'pending_approval', 'success' => 'active', 'danger' => 'suspended']),
                Tables\Columns\TextColumn::make('average_rating')->sortable(),
                Tables\Columns\TextColumn::make('total_reviews')->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(['draft' => 'Draft', 'pending_approval' => 'Pending', 'active' => 'Active', 'suspended' => 'Suspended']),
                Tables\Filters\SelectFilter::make('fuel_type')
                    ->options(['petrol' => 'Petrol', 'diesel' => 'Diesel', 'electric' => 'Electric', 'hybrid' => 'Hybrid']),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\ViewAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCars::route('/'),
            'create' => Pages\CreateCar::route('/create'),
            'edit' => Pages\EditCar::route('/{record}/edit'),
        ];
    }
}
