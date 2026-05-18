<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromoCodeResource\Pages;
use App\Models\PromoCode;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PromoCodeResource extends Resource
{
    protected static ?string $model = PromoCode::class;
    protected static ?string $navigationIcon = 'heroicon-o-tag';
    protected static ?string $navigationGroup = 'Marketing';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('code')->required(),
            Forms\Components\Select::make('type')
                ->options(['percentage' => 'Percentage', 'fixed' => 'Fixed Amount'])->required(),
            Forms\Components\TextInput::make('value')->numeric()->required(),
            Forms\Components\TextInput::make('max_discount')->numeric(),
            Forms\Components\TextInput::make('min_booking_amount')->numeric(),
            Forms\Components\TextInput::make('max_uses')->numeric(),
            Forms\Components\TextInput::make('max_uses_per_user')->numeric(),
            Forms\Components\DateTimePicker::make('valid_from')->required(),
            Forms\Components\DateTimePicker::make('valid_until')->required(),
            Forms\Components\Toggle::make('is_active')->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('type'),
                Tables\Columns\TextColumn::make('value')->sortable(),
                Tables\Columns\TextColumn::make('max_discount'),
                Tables\Columns\TextColumn::make('times_used')->sortable(),
                Tables\Columns\TextColumn::make('max_uses'),
                Tables\Columns\IconColumn::make('is_active')->boolean(),
                Tables\Columns\TextColumn::make('valid_until')->dateTime()->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPromoCodes::route('/'),
            'create' => Pages\CreatePromoCode::route('/create'),
            'edit' => Pages\EditPromoCode::route('/{record}/edit'),
        ];
    }
}
