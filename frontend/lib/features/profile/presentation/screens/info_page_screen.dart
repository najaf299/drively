import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import 'change_password_screen.dart' show SettingsBackButton;

/// A single block of an info page: an optional heading + body paragraph(s).
class InfoSection {
  final String? heading;
  final String body;
  const InfoSection({this.heading, required this.body});
}

/// Static legal / support content (Privacy, Terms, Help, About, Data).
class InfoPageData {
  final String title;
  final String? intro;
  final List<InfoSection> sections;
  const InfoPageData({required this.title, this.intro, required this.sections});
}

/// Renders a static, scrollable information page (legal / help / about copy).
///
/// Driven by a string [pageId] so a single route can serve every legal/support
/// document. Unknown ids fall back to a short placeholder.
class InfoPageScreen extends StatelessWidget {
  final String pageId;
  const InfoPageScreen({super.key, required this.pageId});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = _pages[pageId] ?? _fallback;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spacing.x5, Spacing.x4, Spacing.x5, Spacing.x10),
          children: [
            Row(
              children: [
                const SettingsBackButton(),
                const SizedBox(width: Spacing.x4),
                Expanded(
                  child: Text(data.title, style: text.headlineMedium),
                ),
              ],
            ),
            const SizedBox(height: Spacing.x5),
            if (data.intro != null) ...[
              Text(
                data.intro!,
                style: text.bodyLarge
                    ?.copyWith(color: BrandColors.mutedFg, height: 1.5),
              ),
              const SizedBox(height: Spacing.x6),
            ],
            for (final s in data.sections) ...[
              if (s.heading != null) ...[
                Text(s.heading!,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: Spacing.x2),
              ],
              Text(
                s.body,
                style: text.bodyMedium
                    ?.copyWith(color: BrandColors.mutedFg, height: 1.55),
              ),
              const SizedBox(height: Spacing.x5),
            ],
            const SizedBox(height: Spacing.x2),
            Center(
              child: Text(
                'Drivly · Last updated June 2026',
                style: text.labelSmall?.copyWith(color: BrandColors.subtleFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const InfoPageData _fallback = InfoPageData(
  title: 'Drivly',
  sections: [
    InfoSection(body: 'This page is part of the Drivly demo experience.'),
  ],
);

/// Complete static content for each legal / support page.
const Map<String, InfoPageData> _pages = {
  'privacy': InfoPageData(
    title: 'Privacy policy',
    intro:
        'Your privacy matters to us. This policy explains what we collect, why '
        'we collect it, and the choices you have.',
    sections: [
      InfoSection(
        heading: 'Information we collect',
        body:
            'Account details (name, email, phone), verification documents, trip '
            'and booking history, payment metadata, and approximate location '
            'while a trip is active so we can unlock and lock the vehicle.',
      ),
      InfoSection(
        heading: 'How we use it',
        body:
            'To match you with cars, process bookings and payments, keep the '
            'community safe, prevent fraud, and improve the product. We never '
            'sell your personal data.',
      ),
      InfoSection(
        heading: 'Location data',
        body:
            'GPS is only read during an active trip to verify pickup and return '
            'and to manage the digital lock. You can revoke location access at '
            'any time in your device settings.',
      ),
      InfoSection(
        heading: 'Your rights',
        body:
            'You can access, correct, export or delete your data at any time '
            'from Settings, or by contacting privacy@drivly.io.',
      ),
    ],
  ),
  'security': InfoPageData(
    title: 'Privacy & security',
    intro:
        'Controls that keep your account and your trips safe.',
    sections: [
      InfoSection(
        heading: 'Account protection',
        body:
            'Use a strong, unique password and review your linked accounts '
            'regularly. We sign you out of other devices whenever you change '
            'your password.',
      ),
      InfoSection(
        heading: 'Two-factor verification',
        body:
            'Phone-number verification adds a second layer of security to '
            'sensitive actions like booking and withdrawals.',
      ),
      InfoSection(
        heading: 'Data encryption',
        body:
            'Traffic between the app and Drivly is encrypted in transit, and '
            'verification documents are stored encrypted at rest.',
      ),
    ],
  ),
  'data': InfoPageData(
    title: 'Data & permissions',
    intro:
        'See how Drivly uses your device permissions and manage your data. '
        '(Demo content.)',
    sections: [
      InfoSection(
        heading: 'Location',
        body:
            'Used during active trips to confirm pickup/return and operate the '
            'GPS lock. Not tracked in the background outside of a trip.',
      ),
      InfoSection(
        heading: 'Camera & photos',
        body:
            'Used to upload your profile photo, vehicle photos and verification '
            'documents.',
      ),
      InfoSection(
        heading: 'Notifications',
        body:
            'Used for booking updates, messages and trip reminders. Toggle '
            'these any time under Settings › App.',
      ),
      InfoSection(
        heading: 'Download or delete',
        body:
            'Request a copy of your data or delete your account by emailing '
            'support@drivly.io. Deletion is permanent.',
      ),
    ],
  ),
  'terms': InfoPageData(
    title: 'Terms & policies',
    intro:
        'By using Drivly you agree to these terms. Please read them carefully. '
        '(Demo content.)',
    sections: [
      InfoSection(
        heading: '1. Using Drivly',
        body:
            'You must be at least 21, hold a valid driving licence, and provide '
            'accurate information. You are responsible for activity on your '
            'account.',
      ),
      InfoSection(
        heading: '2. Bookings & payments',
        body:
            'A booking is a contract between renter and host. Prices, deposits '
            'and fees are shown before you confirm. Payment is processed '
            'securely via our payment partner.',
      ),
      InfoSection(
        heading: '3. Cancellations',
        body:
            'Free cancellation up to 24 hours before pickup. Later '
            'cancellations may incur a fee as shown at checkout.',
      ),
      InfoSection(
        heading: '4. Vehicle care',
        body:
            'Return the car on time, in the condition you received it, with a '
            'comparable fuel/charge level. Damage and traffic fines are the '
            "renter's responsibility.",
      ),
      InfoSection(
        heading: '5. Liability',
        body:
            'Drivly facilitates rentals between users and is not the owner of '
            'listed vehicles. Insurance terms apply per trip.',
      ),
    ],
  ),
  'help': InfoPageData(
    title: 'Help center',
    intro: 'Quick answers to common questions.',
    sections: [
      InfoSection(
        heading: 'How do I book a car?',
        body:
            'Browse or search, open a car, pick your dates and tap Book. Confirm '
            'and pay, and your trip appears under Trips.',
      ),
      InfoSection(
        heading: 'How does the GPS lock work?',
        body:
            'Once your payment is confirmed the car unlocks at pickup. When you '
            'end the trip and return the car, it locks automatically.',
      ),
      InfoSection(
        heading: 'How do I get paid as a host?',
        body:
            'Earnings land in your Drivly wallet after each completed trip. '
            'Withdraw to your bank from the Wallet tab.',
      ),
      InfoSection(
        heading: 'I need to contact support',
        body:
            'Email support@drivly.io or message us in-app — we usually reply '
            'within a few minutes during business hours.',
      ),
    ],
  ),
  'about': InfoPageData(
    title: 'About Drivly',
    intro:
        'Drivly is a peer-to-peer car-sharing marketplace — unlock a car with '
        'your phone, drive, and return it when you are done.',
    sections: [
      InfoSection(
        heading: 'Our mission',
        body:
            'Make car access effortless and put idle vehicles to work for their '
            'owners — without keys, counters or paperwork.',
      ),
      InfoSection(
        heading: 'How it works',
        body:
            'Hosts list their cars. Renters book instantly. A GPS-based digital '
            'lock unlocks the car on payment and locks it on return.',
      ),
      InfoSection(
        heading: 'Version',
        body: 'Drivly 1.0.0. Made with Flutter & Laravel.',
      ),
    ],
  ),
};
