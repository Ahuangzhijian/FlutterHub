import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/list_tiles/repository_tile.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../domain/entities/models.dart';
import '../cubit/search/search_cubit.dart';
import '../widgets/tab_bars/search_tab_bar.dart';
import 'repository_page.dart';
import 'user_page.dart';
import '../widgets/empty_widget.dart';
import '../widgets/list_tiles/user_tile.dart';

class SearchDelegatePage extends SearchDelegate {
  SearchDelegatePage(this.type) : super();

  final SearchType type;

  final _refreshController = RefreshController(initialRefresh: true);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResults(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Widget _buildResults(BuildContext context, String query) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return SmartRefresher(
          controller: _refreshController,
          enablePullUp: true,
          onRefresh: () => _onRefresh(context),
          onLoading: () => _onRefresh(context, isLoading: true),
          child: state.when(
            initial: () => Container(),
            reposFetchInProgress: () => Container(),
            reposFetchEmpty: _buildEmptyRepositoriesWidget,
            reposFetchSuccess: (items, hasNextPage) =>
                _buildRepositoriesList(context, items, hasNextPage),
            reposFetchError: _buildFailureWidget,
            usersFetchInProgress: () => Container(),
            usersFetchEmpty: _buildEmptyUsersWidget,
            usersFetchSuccess: (items, hasNextPage) =>
                _buildUsersList(context, items, hasNextPage),
            usersFetchError: _buildFailureWidget,
          ),
        );
      },
    );
  }

  _onRefresh(BuildContext context, {bool isLoading = false}) {
    switch (type) {
      case SearchType.repository:
        context.read<SearchCubit>().fetchRepository(
              query: query,
              isRefresh: !isLoading,
            );
        break;
      case SearchType.user:
        context.read<SearchCubit>().fetchUser(
              query: query,
              isRefresh: !isLoading,
            );
        break;
    }
  }

  endLoadAnimation({
    bool isRefresh = false,
    bool hasNextPage = false,
    bool isFailure = false,
  }) {
    if (isRefresh) {
      _refreshController.refreshCompleted();
    }
    if (hasNextPage) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
    if (isFailure) {
      _refreshController.refreshFailed();
      _refreshController.loadFailed();
    }
  }

  Widget _buildEmptyRepositoriesWidget() {
    endLoadAnimation(isRefresh: true);
    return emptyRepositoriesWidget();
  }

  Widget _buildEmptyUsersWidget() {
    endLoadAnimation(isRefresh: true);
    return emptyUsersWidget();
  }

  Widget _buildRepositoriesList(
      BuildContext context, List<Repository> items, bool hasNextPage) {
    endLoadAnimation(isRefresh: true, hasNextPage: hasNextPage);
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => RepositoryTile(
        item: items[index],
        onTap: (item) => _onRepositorySelected(context, item),
      ),
    );
  }

  Widget _buildUsersList(
      BuildContext context, List<User> items, bool hasNextPage) {
    endLoadAnimation(isRefresh: true, hasNextPage: hasNextPage);
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => UserTile(
        item: items[index],
        onTap: (item) => _onUserSelected(context, item),
      ),
    );
  }

  Widget _buildFailureWidget(String? message, String? url) {
    endLoadAnimation(isFailure: true);
    return serverErrorWidget(message, url);
  }

  _onRepositorySelected(BuildContext context, Repository item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepositoryPage(fullName: item.fullName),
      ),
    );
  }

  _onUserSelected(BuildContext context, User item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPage(owner: item.login),
      ),
    );
  }
}
