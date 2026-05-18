<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BookingResource\Pages;
use App\Models\Booking;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class BookingResource extends Resource
{
    protected static ?string $model = Booking::class;
    protected static ?string $navigationIcon = 'heroicon-o-calendar-days';
    protected static ?string $navigationGroup = 'Bookings';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\TextInput::make('reference')->disabled(),
            Forms\Components\Select::make('status')
                ->options([
                    'pending' => 'Pending', 'confirmed' => 'Confirmed', 'active' => 'Active',
                    'completed' => 'Completed', 'cancelled' => 'Cancelled', 'declined' => 'Declined',
                ]),
            Forms\Components\TextInput::make('total_amount')->numeric()->prefix('$')->disabled(),
            Forms\Components\DateTimePicker::make('pickup_at'),
            Forms\Components\DateTimePicker::make('return_at'),
            Forms\Components\Textarea::make('cancellation_reason'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('reference')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('customer.name')->label('Customer')->searchable(),
                Tables\Columns\TextColumn::make('car.make')->label('Car'),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'pending', 'info' => 'confirmed', 'primary' => 'active',
                        'success' => 'completed', 'danger' => 'cancelled', 'gray' => 'declined',
                    ]),
                Tables\Columns\TextColumn::make('total_amount')->money('usd')->sortable(),
                Tables\Columns\TextColumn::make('pickup_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('return_at')->dateTime(),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending', 'confirmed' => 'Confirmed', 'active' => 'Active',
                        'completed' => 'Completed', 'cancelled' => 'Cancelled', 'declined' => 'Declined',
                    ]),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\ViewAction::make(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBookings::route('/'),
            'edit' => Pages\EditBooking::route('/{record}/edit'),
        ];
    }
}
