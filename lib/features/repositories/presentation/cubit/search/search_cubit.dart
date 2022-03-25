import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutterhub/core/error/failure.dart';
import 'package:flutterhub/features/repositories/domain/usecases/usecases.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/models.dart';

part 'search_state.dart';
part 'search_cubit.freezed.dart';
part 'search_cubit.g.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required this.searchRepositories,
    required this.searchUsers,
  }) : super(const SearchState.loading());

  final SearchRepositoriesUsecase searchRepositories;
  final SearchUsersUsecase searchUsers;

  void search(String query) async {
    emit(const SearchState.loading());
    try {
      final result =
          await searchRepositories(SearchRepositoriesParams(query, 1));
      // final users = await searchUsers(SearchUsersParams(query, 1));
      result.fold(
        (l) => emit(SearchState.error(
          message: l.messageText(),
          url: l.documentationUrlText(),
        )),
        (r) => emit(SearchState.loaded(items: r.items ?? [])),
      );
    } catch (e) {
      debugPrint(e.toString());
      emit(const SearchState.error(message: kUnexpectedError));
    }
  }
}
