import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterhub/configs/app_router.dart';
import 'package:flutterhub/configs/constants.dart';
import 'package:flutterhub/features/domain/entities/models.dart';
import 'package:flutterhub/features/presentation/widgets/network_image.dart';
import 'package:flutterhub/core/extensions.dart';
import 'package:flutterhub/generated/l10n.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/repository/repository_cubit.dart';
import '../widgets/common_widgets.dart';
import '../widgets/empty_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RepositoryPage extends StatefulWidget {
  const RepositoryPage({Key? key, required this.arguments}) : super(key: key);
  final Object? arguments;

  @override
  State<RepositoryPage> createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  final _refreshController = RefreshController(initialRefresh: true);

  String? get fullName => widget.arguments as String;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RepositoryCubit, RepositoryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: ContainerX(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: state.when(
                fetchInProgress: _buildInProgressWidget,
                fetchSuccess: (item) => _buildSuccessWidget(context, item),
                fetchError: (message, url) => _buildErrorWidget(message, url),
              ),
            ),
          ),
        );
      },
    );
  }

  _onRefresh() {
    context.read<RepositoryCubit>().fetchRepository(fullName: fullName ?? '');
  }

  Widget _buildInProgressWidget() {
    return Container();
  }

  Widget _buildErrorWidget(String? message, String? url) {
    _refreshController.refreshFailed();
    return serverErrorWidget(message, url);
  }

  AppBar _buildAppBar(BuildContext context, RepositoryState item) {
    return item.maybeWhen(
      orElse: () => AppBar(
        title: Text(fullName ?? ''),
      ),
      fetchSuccess: (item) => AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.user,
              arguments: item.owner?.login,
            );
          },
          child: Row(
            children: [
              networkImage(
                context,
                item.owner?.avatarUrl,
                width: 44,
                height: 44,
              ),
              const SizedBox(width: spaceDefault),
              Expanded(child: Text(item.owner?.login ?? '')),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.github),
            onPressed: () {
              launchUrl(Uri.parse(item.htmlUrl ?? ''));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(BuildContext context, Repository item) {
    _refreshController.refreshCompleted();
    return Padding(
      padding: paddingSmallMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: spaceDefault),
          _buildRepositoryInfo(context, item),
          _buildStats(context, item),
          if (item.topics != null) _buildTopics(context, item.topics),
          _buildRepoActions(context, item),
        ],
      ),
    );
  }

  Widget _buildRepositoryInfo(BuildContext context, Repository item) {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.bookBookmark, size: 32),
      title: Text(item.fullName ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.description ?? ''),
        ],
      ),
      isThreeLine: true,
    );
  }

  // Repository size, created at and updated at
  Widget _buildStats(BuildContext context, Repository item) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        children: [
          if (item.size != null)
            _buildRepoInfoItem(
              FontAwesomeIcons.sdCard,
              filesize('${(item.size ?? 0).toInt()}'),
            ),
          if (item.createdAt != null)
            _buildRepoInfoItem(
              FontAwesomeIcons.calendarPlus,
              '${item.createdAt?.toTimeAgoString()}',
            ),
          if (item.updatedAt != null)
            _buildRepoInfoItem(
              FontAwesomeIcons.clock,
              '${item.updatedAt?.toTimeAgoString()}',
            ),
        ],
      ),
    );
  }

  Widget _buildRepoInfoItem(IconData? icon, String? text) {
    return text == null || text.isEmpty
        ? Container()
        : Padding(
            padding: paddingSmallMedium,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Center(child: Icon(icon, size: 14)),
                  const SizedBox(width: spaceMedium),
                ],
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyText2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
  }

  // Repository watching, forks and stars
  Widget _buildRepoActions(BuildContext context, Repository item) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionButton(
            context,
            FontAwesomeIcons.eye,
            S.current.watching,
            item.subscribersCount,
          ),
          _buildActionButton(
            context,
            FontAwesomeIcons.codeBranch,
            S.current.forks,
            item.forksCount,
          ),
          _buildActionButton(
            context,
            FontAwesomeIcons.star,
            S.current.stars,
            item.stargazersCount,
          ),
        ],
      ),
    );
  }

  _buildActionButton(
      BuildContext context, IconData icon, String title, int? count) {
    return Card(
      child: Padding(
        padding: paddingSmallMedium,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: spaceMedium),
            Column(
              children: [
                Text(
                  NumberFormat.compact().format(count),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopics(BuildContext context, List<String>? topics) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: paddingSmallMedium,
        child: Wrap(
          spacing: spaceSmall2,
          children: topics
                  ?.map((topic) => Chip(
                        label: Text(topic),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.4),
                      ))
                  .toList() ??
              [],
        ),
      ),
    );
  }
}
