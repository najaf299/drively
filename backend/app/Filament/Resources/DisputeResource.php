<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DisputeResource\Pages;
use App\Models\Dispute;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DisputeResource extends Resource
{
    protected static ?string $model = Dispute::class;
    protected static ?string $navigationIcon = 'heroicon-o-exclamation-triangle';
    protected static ?string $navigationGroup = 'Support';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Select::make('status')
                ->options(['open' => 'Open', 'investigating' => 'Investigating', 'resolved' => 'Resolved', 'dismissed' => 'Dismissed']),
            Forms\Components\Textarea::make('description')->disabled(),
            Forms\Components\Textarea::make('resolution'),
            Forms\Components\TextInput::make('refund_amount')->numeric()->prefix('$'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('booking.reference')->label('Booking')->searchable(),
                Tables\Columns\TextColumn::make('reporter.name')->label('Reporter')->searchable(),
                Tables\Columns\TextColumn::make('type')->sortable(),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors(['warning' => 'open', 'info' => 'investigating', 'success' => 'resolved', 'gray' => 'dismissed']),
                Tables\Columns\TextColumn::make('refund_amount')->money('usd'),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(['open' => 'Open', 'investigating' => 'Investigating', 'resolved' => 'Resolved', 'dismissed' => 'Dismissed']),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDisputes::route('/'),
            'edit' => Pages\EditDispute::route('/{record}/edit'),
        ];
    }
}
