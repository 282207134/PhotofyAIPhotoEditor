import 'package:flutter/material.dart';

import '../session.dart';
import '../ui.dart';
import 'access.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    return Screen(
      title: 'Settings',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundImage: AssetImage(art('profile.webp')),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Heading(session.profile['Full Name']!, size: 19),
                    const SizedBox(height: 3),
                    Text(
                      session.profile['Email']!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          gap,
          Material(
            color: brand,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => open(context, const Pro()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.workspace_premium,
                        color: Color(0xffe5a419),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.pro ? 'Photofy PRO' : 'Upgrade to PRO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Enjoy all features & benefits without any restrictions',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          gap,
          const _Section('General'),
          menuRow(
            context,
            'Personal Info',
            icon: Icons.person_outline,
            onTap: () => open(context, const PersonalInfo()),
          ),
          menuRow(
            context,
            'Payment Methods',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => open(context, const PaymentMethods()),
          ),
          menuRow(
            context,
            'Security',
            icon: Icons.shield_outlined,
            onTap: () => open(context, const Security()),
          ),
          menuRow(
            context,
            'Language',
            icon: Icons.language,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(session.language),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => open(context, const Language()),
          ),
          menuRow(
            context,
            'Dark Mode',
            icon: Icons.dark_mode_outlined,
            trailing: Switch(
              value: session.dark,
              onChanged: session.toggleTheme,
            ),
            onTap: () => session.toggleTheme(!session.dark),
          ),
          const Divider(),
          const _Section('About'),
          menuRow(
            context,
            'Follow us on Social Media',
            icon: Icons.people_alt_outlined,
            onTap: () =>
                open(context, const InfoPage('Follow us on Social Media')),
          ),
          menuRow(
            context,
            'Help Center',
            icon: Icons.help_outline,
            onTap: () => open(context, const HelpCenter()),
          ),
          menuRow(
            context,
            'Privacy Policy',
            icon: Icons.lock_outline,
            onTap: () => open(context, const InfoPage('Privacy Policy')),
          ),
          menuRow(
            context,
            'About Photofy',
            icon: Icons.info_outline,
            onTap: () => open(context, const InfoPage('About Photofy')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            textColor: Colors.red,
            iconColor: Colors.red,
            leading: const Icon(Icons.logout, size: 21),
            title: const Text('Logout'),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    final confirmed = await sheet<bool>(
      context,
      Builder(
        builder: (context) => Column(
          children: [
            const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 30),
            const Heading(
              'Are you sure you want to log out?',
              size: 19,
              align: TextAlign.center,
            ),
            largeGap,
            Row(
              children: [
                Expanded(
                  child: Pill(
                    'Cancel',
                    () => Navigator.pop(context, false),
                    soft: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Pill(
                    'Yes, Logout',
                    () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (context.mounted && confirmed == true) {
      Session.of(context).clearAccount();
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: context.muted,
      ),
    ),
  );
}

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});
  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final changes = <String, String>{};
  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    return Screen(
      title: 'Personal Info',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundImage: AssetImage(art('profile.webp')),
            ),
          ),
          largeGap,
          for (final entry in session.profile.entries)
            Field(
              entry.key,
              initial: entry.value,
              keyboard: switch (entry.key) {
                'Email' => TextInputType.emailAddress,
                'Phone Number' => TextInputType.phone,
                _ => TextInputType.text,
              },
              onChanged: (value) => changes[entry.key] = value.trim(),
            ),
        ],
      ),
      bottom: BottomActions([
        Pill('Save', () {
          if (changes['Full Name'] == '' || changes['Email'] == '') {
            notice(context, 'Full name and email are required.');
            return;
          }
          session.updateProfile(changes);
          Navigator.pop(context);
          notice(context, 'Personal info saved');
        }),
      ]),
    );
  }
}

class Security extends StatefulWidget {
  const Security({super.key});
  @override
  State<Security> createState() => _SecurityState();
}

class _SecurityState extends State<Security> {
  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    return Screen(
      title: 'Security',
      body: Column(
        children: [
          menuRow(
            context,
            'Remember me',
            trailing: Switch(
              value: session.remember,
              onChanged: (value) => setState(() => session.remember = value),
            ),
          ),
          for (final label in const [
            'Biometric ID',
            'Face ID',
            'SMS Authenticator',
            'Google Authenticator',
          ])
            menuRow(
              context,
              label,
              trailing: Switch(
                value: session.security.contains(label),
                onChanged: (value) => setState(() {
                  if (value) {
                    session.security.add(label);
                  } else {
                    session.security.remove(label);
                  }
                }),
              ),
            ),
          menuRow(
            context,
            'Device Management',
            onTap: () => open(
              context,
              const Screen(
                title: 'Device Management',
                body: ListTile(
                  leading: Icon(Icons.smartphone),
                  title: Text('This Android device'),
                  subtitle: Text('Local session'),
                ),
              ),
            ),
          ),
          menuRow(
            context,
            'Change Password',
            onTap: () => open(
              context,
              Access(AccessStage.password, email: session.profile['Email']!),
            ),
          ),
        ],
      ),
    );
  }
}

class Language extends StatelessWidget {
  const Language({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    Widget options(List<String> items) => Column(
      children: [
        for (final language in items)
          menuRow(
            context,
            language,
            trailing: Icon(
              language == session.language
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: brand,
              size: 21,
            ),
            onTap: () => session.setLanguage(language),
          ),
      ],
    );
    return Screen(
      title: 'Language',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Section('Suggested'),
          options(const ['English (US)', 'English (UK)']),
          const Divider(),
          const _Section('Language'),
          options(const [
            'Mandarin',
            'Spanish',
            'Hindi',
            'French',
            'Arabic',
            'Bengali',
            'Russian',
            'Japanese',
            'Korean',
            'Indonesia',
          ]),
        ],
      ),
    );
  }
}

const _faq = [
  (
    'General',
    'What is Photofy?',
    'Photofy is a photo editor with image adjustments, filters, cropping and previews of AI editing tools.',
  ),
  (
    'General',
    'Is the Photofy App free?',
    'The local preview is free. The PRO screen demonstrates available plans.',
  ),
  (
    'AI Photo',
    'How does the Photofy app work?',
    'Choose a photo or sample, select a tool and preview the result.',
  ),
  (
    'AI Photo',
    'What do I use the Photofy app for?',
    'Edit photos, explore style previews, and export images to your gallery.',
  ),
  (
    'Subscription',
    'Can I use Photofy for commercial?',
    'Commercial usage depends on the rights to the original photo and any artwork used.',
  ),
  (
    'Account',
    'Can I use my own media in Photofy?',
    'Yes. Choose an image from your Android gallery to edit it locally.',
  ),
];

class HelpCenter extends StatefulWidget {
  const HelpCenter({super.key});
  @override
  State<HelpCenter> createState() => _HelpCenterState();
}

class _HelpCenterState extends State<HelpCenter> {
  String category = 'General';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final questions = _faq
        .where(
          (item) =>
              (category == 'General' || category == item.$1) &&
              '${item.$2} ${item.$3}'.toLowerCase().contains(query),
        )
        .toList();
    return Screen(
      title: 'Help Center',
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final name in const [
                  'General',
                  'Account',
                  'AI Photo',
                  'Subscription',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: category == name,
                      onSelected: (_) => setState(() => category = name),
                    ),
                  ),
              ],
            ),
          ),
          gap,
          TextField(
            onChanged: (value) =>
                setState(() => query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: context.panel,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          gap,
          if (questions.isEmpty) const Text('No matching questions'),
          for (final item in questions)
            Padding(
              key: ValueKey(item.$2),
              padding: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  item.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                initiallyExpanded: item == _faq.first,
                backgroundColor: context.panel,
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text(item.$3)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    final social = title == 'Follow us on Social Media';
    final privacy = title == 'Privacy Policy';
    return Screen(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!social && !privacy) ...[
            largeGap,
            const Center(child: Mark(size: 70)),
            gap,
            const Heading('Photofy v1.0.0', align: TextAlign.center),
            largeGap,
            const Divider(),
          ],
          if (privacy) ...[
            const Heading('Privacy Policy'),
            gap,
            const Text(
              'Photofy opens photos you select through the Android picker. Editing and previewing take place on the device. Choosing Save creates an image in your gallery.',
            ),
            largeGap,
            const Heading('Local data', size: 19),
            gap,
            const Text(
              'Selected photos may be copied into app cache for editing. Theme preference is stored on the device. Demo profile and payment choices are kept in memory for the current session.',
            ),
            largeGap,
            const Heading('Sharing', size: 19),
            gap,
            const Text(
              'Sharing opens the Android share menu. The receiving app handles the copy you choose to share.',
            ),
          ] else
            for (final name
                in social
                    ? const [
                        'Twitter',
                        'Instagram',
                        'Discord',
                        'Reddit',
                        'Telegram',
                        'YouTube',
                      ]
                    : const [
                        'Job Vacancy',
                        'Developer',
                        'Partner',
                        'Accessibility',
                        'Terms of Use',
                        'Feedback',
                        'Rate us',
                        'Visit Our Website',
                        'Follow us on Social Media',
                      ])
              menuRow(
                context,
                name,
                onTap: () {
                  if (name == 'Follow us on Social Media') {
                    open(context, InfoPage(name));
                  } else {
                    open(
                      context,
                      Screen(
                        title: name,
                        body: const Text(
                          'This link is available when the Photofy service is connected.',
                        ),
                      ),
                    );
                  }
                },
              ),
        ],
      ),
    );
  }
}

const _benefits = [
  'Remove Ads',
  'Unlimited Photo Editing',
  'Advanced Editing Tools',
  'Faster Processing Times',
  'Remove Watermarks',
  'Download Results in High Resolution',
  'Customization Options',
  'Exclusive Filters and Effects',
  'Priority Queue',
  'Priority Customer Support',
  'Priority Access to New Features',
  'Commercial Use Rights',
];
const _plans = [
  ('1 Month', 'Pro access for 1 month', 5),
  ('3 Months', 'You save 10%', 14),
  ('6 Months', 'You save 20%', 24),
  ('12 Months', 'You save 30%', 40),
  ('Lifetime', 'Limited time and offer', 120),
];
String _money(int price) => '\$${price.toStringAsFixed(2)}';

class Pro extends StatelessWidget {
  const Pro({super.key});

  @override
  Widget build(BuildContext context) => Screen(
    title: '',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: const BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: const DefaultTextStyle(
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Urbanist',
              fontSize: 16,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
            child: Column(
              children: [
                Heading('UPGRADE TO PRO', size: 24),
                SizedBox(height: 6),
                Text('Enjoy all features & benefits without any restrictions'),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.panel,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
          ),
          child: Column(
            children: [
              for (final text in _benefits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 19, color: brand),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    bottom: BottomActions([
      Pill('Upgrade to PRO', () => open(context, const Plans())),
    ]),
  );
}

class Plans extends StatefulWidget {
  const Plans({super.key});
  @override
  State<Plans> createState() => _PlansState();
}

class _PlansState extends State<Plans> {
  int selected = 2;

  @override
  Widget build(BuildContext context) => Screen(
    title: 'Choose Your Plan',
    body: Column(
      children: [
        for (final (i, plan) in _plans.indexed)
          _PaymentTile(
            label: plan.$1,
            description: plan.$2,
            selected: selected == i,
            trailing: _money(plan.$3),
            onTap: () => setState(() => selected = i),
          ),
      ],
    ),
    bottom: BottomActions([
      Pill('Continue', () => open(context, PaymentMethods(plan: selected))),
    ]),
  );
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.label,
    this.description,
    this.trailing,
    this.selected,
    this.onTap,
    this.mark,
  });
  final String label;
  final String? description;
  final String? trailing;
  final bool? selected;
  final VoidCallback? onTap;
  final Widget? mark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: context.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected == true ? brand : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          child: Row(
            children: [
              if (mark != null) ...[mark!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Heading(label, size: 17),
                    if (description != null)
                      Text(
                        description!,
                        style: TextStyle(color: context.muted, fontSize: 13),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected == null ? brand : context.ink,
                  ),
                ),
              if (selected != null) ...[
                const SizedBox(width: 9),
                Icon(
                  selected!
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: brand,
                  size: 21,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class PaymentMethods extends StatefulWidget {
  const PaymentMethods({this.plan, super.key});
  final int? plan;
  @override
  State<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {
  int selected = 3;

  @override
  Widget build(BuildContext context) {
    final methods = [
      'PayPal',
      'Google Pay',
      'Apple Pay',
      ...Session.of(context).cards,
    ];
    final checkout = widget.plan != null;
    void add() => open(context, const AddPayment());
    return Screen(
      title: checkout ? 'Select Payment Method' : 'Payment Methods',
      actions: checkout
          ? [
              IconButton(
                tooltip: 'Add New Payment',
                onPressed: add,
                icon: const Icon(Icons.add),
              ),
            ]
          : null,
      body: Column(
        children: [
          for (final (i, method) in methods.indexed)
            _PaymentTile(
              label: method,
              mark: _PaymentMark(i),
              selected: checkout ? selected == i : null,
              trailing: checkout ? null : 'Connected',
              onTap: checkout ? () => setState(() => selected = i) : null,
            ),
        ],
      ),
      bottom: BottomActions([
        Pill(
          checkout ? 'Continue' : 'Add New Payment',
          checkout
              ? () => open(
                  context,
                  Review(
                    plan: widget.plan!,
                    method: methods[selected],
                    methodIndex: selected,
                  ),
                )
              : add,
        ),
      ]),
    );
  }
}

class _PaymentMark extends StatelessWidget {
  const _PaymentMark(this.index);
  final int index;
  @override
  Widget build(BuildContext context) {
    final (name, color) = switch (index) {
      0 => ('P', const Color(0xff0572c9)),
      1 => ('G', const Color(0xff4285f4)),
      2 => ('', const Color(0xff161617)),
      3 => ('VISA', const Color(0xff144aba)),
      _ => ('CARD', const Color(0xff1394dc)),
    };
    return CircleAvatar(
      radius: 22,
      backgroundColor: color,
      foregroundColor: Colors.white,
      child: index == 2
          ? const Icon(Icons.apple)
          : Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: index > 2 ? 10 : 23,
              ),
            ),
    );
  }
}

class Review extends StatelessWidget {
  const Review({
    required this.plan,
    required this.method,
    required this.methodIndex,
    super.key,
  });
  final int plan;
  final String method;
  final int methodIndex;

  Widget breakdown(BuildContext context, List<(String, String)> rows) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: context.muted)),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final (name, _, price) = _plans[plan];
    return Screen(
      title: 'Review Summary',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          breakdown(context, [
            ('Subscription', name),
            ('Price', _money(price)),
          ]),
          gap,
          breakdown(context, [
            ('Amount', _money(price)),
            ('Tax', _money(1)),
            ('Total Amount', _money(price + 1)),
          ]),
          largeGap,
          const Heading('Selected Payment Method', size: 19),
          gap,
          _PaymentTile(
            label: method,
            mark: _PaymentMark(methodIndex),
            trailing: 'Change',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
      bottom: BottomActions([
        Pill('Confirm Payment', () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.workspace_premium, color: brand, size: 65),
              title: const Heading(
                'Welcome to PRO Plan!',
                align: TextAlign.center,
              ),
              content: Text(
                'Your $name demo subscription is ready.',
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Pill('OK', () {
                  Session.of(context).activatePro();
                  Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                }),
              ],
            ),
          );
        }),
      ]),
    );
  }
}

class AddPayment extends StatefulWidget {
  const AddPayment({super.key});
  @override
  State<AddPayment> createState() => _AddPaymentState();
}

class _AddPaymentState extends State<AddPayment> {
  String holder = '';
  String digits = '';
  String expires = '';
  String cvv = '';

  @override
  Widget build(BuildContext context) => Screen(
    title: 'Add New Payment',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Urbanist',
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Card'),
                    Icon(Icons.contactless, color: Colors.white),
                  ],
                ),
                Text(
                  digits.length < 4
                      ? '••••  ••••  ••••  ••••'
                      : '••••  ••••  ••••  ${digits.substring(digits.length - 4)}',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        holder.isEmpty ? 'Card Holder Name' : holder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(expires.isEmpty ? '00/00' : expires),
                  ],
                ),
              ],
            ),
          ),
        ),
        largeGap,
        Field(
          'Card Holder Name',
          onChanged: (value) => setState(() => holder = value.trim()),
        ),
        Field(
          'Card Number',
          keyboard: TextInputType.number,
          onChanged: (value) =>
              setState(() => digits = value.replaceAll(RegExp(r'\D'), '')),
        ),
        Row(
          children: [
            Expanded(
              child: Field(
                'Expiry Date',
                hint: 'MM/YY',
                onChanged: (value) => setState(() => expires = value.trim()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Field(
                'CVV',
                secret: true,
                keyboard: TextInputType.number,
                onChanged: (value) => cvv = value.trim(),
              ),
            ),
          ],
        ),
        const Text('Use sample values in this payment preview.'),
      ],
    ),
    bottom: BottomActions([
      Pill('Add', () {
        if (holder.isEmpty ||
            digits.length < 12 ||
            digits.length > 19 ||
            !RegExp(r'^(0[1-9]|1[0-2])/\d\d$').hasMatch(expires) ||
            !RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
          notice(
            context,
            'Enter a demo name, card number, expiry date and CVV.',
          );
          return;
        }
        Session.of(context).addCard(digits.substring(digits.length - 4));
        Navigator.pop(context);
        notice(context, 'New payment method added');
      }),
    ]),
  );
}
