import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../session.dart';
import '../ui.dart';

class Intro extends StatefulWidget {
  const Intro({super.key});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> {
  final controller = PageController();
  int index = 0;
  bool splash = true;
  static const titles = [
    'Edit your photos simply in just one click',
    'Unleash your creativity with AI toolbox',
    'Enjoy all the benefits with pro subscriptions',
  ];
  static const captions = [
    'Make quick adjustments, crop your photos and try new filters.',
    'Explore scenes, avatars, backgrounds and more in the AI toolbox.',
    'Unlock more editing options and higher-resolution downloads.',
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void complete() => Navigator.of(context).pushReplacementNamed('/welcome');

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return const Screen(
        scroll: false,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Mark(), gap, Heading('Photofy', size: 38)],
          ),
        ),
      );
    }
    return Screen(
      padding: EdgeInsets.zero,
      scroll: false,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: titles.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.fromLTRB(side, 12, side, 14),
                child: Column(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0, .76, 1],
                        ).createShader(bounds),
                        child: Image.asset(
                          art('intro$i.webp'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    gap,
                    Heading(titles[i], size: 30, align: TextAlign.center),
                    gap,
                    Text(captions[i], textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 21),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < titles.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: i == index ? 28 : 7,
                    decoration: BoxDecoration(
                      color: i == index ? brand : context.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottom: BottomActions(
        index == 2
            ? [Pill('Get Started', complete)]
            : [
                Pill('Skip', complete, soft: true),
                Pill(
                  'Next',
                  () => controller.nextPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  ),
                ),
              ],
      ),
    );
  }
}

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) => Screen(
    body: Column(
      children: [
        const SizedBox(height: 41),
        const Mark(size: 88),
        const SizedBox(height: 46),
        const Heading('Photofy', size: 42),
        gap,
        const Text(
          "Welcome! Let's dive in into your account!",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        for (final (label, icon) in const [
          ('Google', Icons.g_mobiledata),
          ('Apple', Icons.apple),
          ('Facebook', Icons.facebook),
          ('Twitter', Icons.alternate_email),
        ]) ...[
          SizedBox(
            width: double.infinity,
            child: Pill(
              'Continue with $label',
              () => notice(
                context,
                '$label sign-in is available when an account provider is connected.',
              ),
              icon: icon,
              outline: true,
            ),
          ),
          gap,
        ],
        largeGap,
        SizedBox(
          width: double.infinity,
          child: Pill(
            'Sign in with password',
            () => open(context, const Access(AccessStage.signIn)),
          ),
        ),
        largeGap,
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Don’t have an account?'),
            TextButton(
              onPressed: () => open(context, const Access(AccessStage.signUp)),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    ),
  );
}

enum AccessStage { signIn, signUp, reset, otp, password, profile }

class Access extends StatefulWidget {
  const Access(this.stage, {this.email = '', super.key});
  final AccessStage stage;
  final String email;

  @override
  State<Access> createState() => _AccessState();
}

class _AccessState extends State<Access> {
  late final email = TextEditingController(text: widget.email);
  final password = TextEditingController();
  final confirm = TextEditingController();
  final profile = <String, String>{};
  String otp = '';
  bool checked = false;
  bool showPassword = false;

  AccessStage get stage => widget.stage;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void finish(String title) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: brand, size: 68),
        title: Heading(title, align: TextAlign.center),
        content: const Text(
          'Your local preview is ready. Continue to the homepage.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Pill('Continue', () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          }),
        ],
      ),
    );
  }

  bool get validEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim());

  void next() {
    final session = Session.of(context);
    switch (stage) {
      case AccessStage.signIn:
      case AccessStage.signUp:
        if (!validEmail || password.text.length < 6) {
          notice(
            context,
            'Enter a valid email and a password with at least 6 characters.',
          );
          return;
        }
        if (stage == AccessStage.signUp) {
          if (!checked) {
            notice(context, 'Accept the terms to continue.');
            return;
          }
          open(context, Access(AccessStage.profile, email: email.text.trim()));
        } else {
          session.remember = checked;
          session.updateProfile({'Email': email.text.trim()});
          finish('Sign in Successful!');
        }
      case AccessStage.reset:
        if (!validEmail) {
          notice(context, 'Enter a valid email address.');
          return;
        }
        open(context, Access(AccessStage.otp, email: email.text.trim()));
      case AccessStage.otp:
        if (otp.length != 4) {
          notice(context, 'Enter a 4 digit demo code.');
          return;
        }
        open(context, Access(AccessStage.password, email: widget.email));
      case AccessStage.password:
        if (password.text.length < 6 || password.text != confirm.text) {
          notice(
            context,
            'Enter matching passwords with at least 6 characters.',
          );
          return;
        }
        session.updateProfile({'Email': widget.email});
        finish('Reset Password Successful!');
      case AccessStage.profile:
        session.updateProfile({'Email': widget.email, ...profile});
        finish('Sign up Successful!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final signIn = stage == AccessStage.signIn;
    final signUp = stage == AccessStage.signUp;
    final (title, description, cta) = switch (stage) {
      AccessStage.signIn => (
        'Welcome back 👋',
        'Please enter your email & password to sign in.',
        'Sign in',
      ),
      AccessStage.signUp => (
        'Hello there 👋',
        'Please enter your email & password to create an account.',
        'Sign up',
      ),
      AccessStage.reset => (
        'Reset your password 🔑',
        'Enter your email to continue to demo code verification.',
        'Continue',
      ),
      AccessStage.otp => (
        'OTP code verification 🔐',
        'Enter any four digits to preview verification for ${widget.email}.',
        'Verify',
      ),
      AccessStage.password => (
        'Create new password 🔒',
        'Choose and confirm your new password.',
        'Continue',
      ),
      AccessStage.profile => (
        'Enter personal info 📋',
        'Enter your profile details, or skip this step for now.',
        'Continue',
      ),
    };
    final fields = [
      if (signIn || signUp || stage == AccessStage.reset)
        Field(
          'Email',
          controller: email,
          keyboard: TextInputType.emailAddress,
          icon: Icons.mail_outline,
        ),
      if (signIn || signUp || stage == AccessStage.password)
        Field(
          stage == AccessStage.password ? 'New Password' : 'Password',
          controller: password,
          secret: !showPassword,
          icon: Icons.lock_outline,
          trailing: IconButton(
            tooltip: 'Show or hide password',
            onPressed: () => setState(() => showPassword = !showPassword),
            icon: Icon(
              showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      if (stage == AccessStage.password)
        Field(
          'Confirm New Password',
          controller: confirm,
          secret: !showPassword,
          icon: Icons.lock_outline,
        ),
      if (signIn || signUp) ...[
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => checked = !checked),
                child: Row(
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (value) => setState(() => checked = value!),
                    ),
                    Expanded(
                      child: Text(
                        signIn
                            ? 'Remember me'
                            : 'I agree to Photofy Terms & Privacy Policy.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (signIn)
              TextButton(
                onPressed: () =>
                    open(context, Access(AccessStage.reset, email: email.text)),
                child: const Text('Forgot password?'),
              ),
          ],
        ),
        largeGap,
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                signIn ? 'Don’t have an account?' : 'Already have an account?',
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => Access(
                      signIn ? AccessStage.signUp : AccessStage.signIn,
                    ),
                  ),
                ),
                child: Text(signIn ? 'Sign up' : 'Sign in'),
              ),
            ],
          ),
        ),
        gap,
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (name, icon) in const [
              ('Google', Icons.g_mobiledata),
              ('Apple', Icons.apple),
              ('Facebook', Icons.facebook),
              ('Twitter', Icons.alternate_email),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: IconButton.outlined(
                  tooltip: name,
                  onPressed: () => notice(
                    context,
                    '$name sign-in requires an account provider.',
                  ),
                  icon: Icon(icon),
                ),
              ),
          ],
        ),
      ],
      if (stage == AccessStage.otp) ...[
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            letterSpacing: 18,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            hintText: '0000',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => otp = value,
        ),
        gap,
        Center(
          child: TextButton(
            onPressed: () =>
                notice(context, 'Use any four digits to continue.'),
            child: const Text('Didn’t receive email?'),
          ),
        ),
      ],
      if (stage == AccessStage.profile)
        for (final field in const [
          'Full Name',
          'Phone Number',
          'Date of Birth',
          'Gender',
          'Street Address',
        ])
          Field(field, onChanged: (value) => profile[field] = value.trim()),
    ];
    return Screen(
      title: '',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Heading(title, size: 34),
          gap,
          Text(description, style: TextStyle(color: context.muted)),
          largeGap,
          ...fields,
        ],
      ),
      bottom: BottomActions([
        if (stage == AccessStage.profile)
          Pill('Skip', () {
            Session.of(context).updateProfile({'Email': widget.email});
            finish('Sign up Successful!');
          }, soft: true),
        Pill(cta, next),
      ]),
    );
  }
}
