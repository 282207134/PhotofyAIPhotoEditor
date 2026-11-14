import 'package:flutter/material.dart';
import '../session.dart';
import '../ui.dart';
import 'account.dart';
import 'editor.dart';
import 'photo_data.dart';
import 'tool_flow.dart';
import 'tools.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    return Screen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => open(context, const Settings()),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(art('profile.webp')),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back 👋',
                              style: TextStyle(
                                color: context.muted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.profile['Full Name']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => open(context, const Pro()),
                icon: const Icon(Icons.workspace_premium, size: 17),
                label: const Text('PRO'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => open(context, const Settings()),
                icon: const Icon(Icons.settings_outlined),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          largeGap,
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: brand,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: .52,
                        heightFactor: 1,
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Colors.transparent, Colors.white],
                            stops: [0, .52],
                          ).createShader(rect),
                          child: Image.asset(
                            art('banner.webp'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const FractionallySizedBox(
                        widthFactor: .67,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Unleash your creativity with the AI multi-editing toolbox!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () async {
                          final photo = await choosePhoto(
                            context,
                            const Photo.asset('editor.webp'),
                          );
                          if (context.mounted && photo != null) {
                            open(context, Editor(photo));
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brand,
                          minimumSize: const Size(0, 35),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Select Photo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          largeGap,
          GridView.builder(
            itemCount: PhotoTool.values.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, i) {
              final tool = PhotoTool.values[i];
              return Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => open(context, ToolFlow(tool)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(art(tool.cover), fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xcc000000), Colors.transparent],
                              stops: [0, .47],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 8,
                          bottom: 9,
                          child: Text(
                            tool.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
