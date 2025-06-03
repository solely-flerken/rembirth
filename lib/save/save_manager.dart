import 'package:rembirth/model/syncable_item.dart';
import 'package:rembirth/save/save_mode.dart';
import 'package:rembirth/save/save_service.dart';

import '../util/logger.dart';

class SaveManager<T extends SyncableItem> {
  final SaveService<T> localService;
  final SaveService<T>? remoteService;
  final SaveMode saveMode;

  SaveManager({required this.localService, this.remoteService, required this.saveMode})
    : assert(
        saveMode != SaveMode.remote || remoteService != null,
        'remoteService must not be null if saveMode is remote',
      ) {
    logger.d('SaveManager: Initialized with mode: ${saveMode.name}');
  }

  Future<void> save(T item) async {
    item.updatedAt = DateTime.now();
    logger.d('SaveManager: Saving item of type ${item.runtimeType} with ID ${item.id} (mode: ${saveMode.name})');

    if (saveMode == SaveMode.local) {
      // Save to local
      await localService.save(item);
    } else if (saveMode == SaveMode.remote) {
      // Save to local and remote
      await localService.save(item);

      if (remoteService != null) {
        await remoteService!.save(item);
      }
    }
  }

  Future<T?> load(dynamic id) async {
    final typeName = T.toString();

    logger.d('SaveManager: Loading item of type $typeName with ID $id (mode: ${saveMode.name})');

    if (saveMode == SaveMode.local) {
      final item = await localService.load(id);
      logger.i('SaveManager: Loaded $typeName with ID ${item?.id} from LOCAL.');
      return item;
    }

    if (saveMode == SaveMode.remote) {
      final results = await Future.wait([localService.load(id), remoteService!.load(id)]);

      final T? itemFromLocal = results[0];
      final T? itemFromRemote = results[1];

      if (itemFromLocal == null && itemFromRemote == null) {
        logger.w('SaveManager: No item of type $typeName with ID $id found locally or remotely.');
        return null;
      }

      if (itemFromLocal == null) {
        await localService.save(itemFromRemote!);
        logger.i('SaveManager: Loaded $typeName with ID ${itemFromRemote.id} from REMOTE, saved to LOCAL.');
        return itemFromRemote;
      }

      if (itemFromRemote == null) {
        await remoteService!.save(itemFromLocal);
        logger.i('SaveManager: Loaded $typeName with ID ${itemFromLocal.id} from LOCAL, saved to REMOTE.');
        return itemFromLocal;
      }

      final isRemoteNewer = itemFromRemote.updatedAt.isAfter(itemFromLocal.updatedAt);

      if (isRemoteNewer) {
        await localService.save(itemFromRemote);
        logger.i('SaveManager: Loaded $typeName with ID ${itemFromRemote.id} (remote is newer), updated LOCAL.');
        return itemFromRemote;
      } else {
        await remoteService!.save(itemFromLocal);
        logger.i('SaveManager: Loaded $typeName with ID ${itemFromLocal.id} (local is newer), updated REMOTE.');
        return itemFromLocal;
      }
    }

    return null;
  }

  Future<List<T>> loadAll() async {
    final typeName = T.toString();

    if (saveMode == SaveMode.local) {
      final list = await localService.loadAll();
      logger.i('SaveManager: Loaded ${list.length} items of type $typeName from LOCAL.');
      return list;
    }

    if (saveMode == SaveMode.remote) {
      final List<T> localItems = await localService.loadAll();
      final List<T> remoteItems = await remoteService!.loadAll();

      if(localItems.isNotEmpty){
        logger.i('SaveManager: Loaded ${localItems.length} items of type $typeName from LOCAL.');
      }
      if(remoteItems.isNotEmpty){
        logger.i('SaveManager: Loaded ${remoteItems.length} items of type $typeName from REMOTE.');
      }

      final localMap = {for (var item in localItems) item.id: item};
      final remoteMap = {for (var item in remoteItems) item.id: item};
      final merged = <dynamic, T>{};

      final allIds = {...localMap.keys, ...remoteMap.keys};

      for (final id in allIds) {
        final localItem = localMap[id];
        final remoteItem = remoteMap[id];

        if (localItem != null && remoteItem != null) {
          // Both exist → resolve with Last Write Wins
          if (remoteItem.updatedAt.isAfter(localItem.updatedAt)) {
            merged[id] = remoteItem;
            await localService.save(remoteItem);
            logger.i('Updated LOCAL: $typeName with ID $id (remote newer)');
          } else if (localItem.updatedAt.isAfter(remoteItem.updatedAt)) {
            merged[id] = localItem;
            await remoteService!.save(localItem);
            logger.i('Updated REMOTE: $typeName with ID $id (local newer)');
          } else {
            merged[id] = localItem; // Timestamps equal → pick either
            logger.i('No sync needed for $typeName with ID $id (timestamps equal)');
          }
        } else if (localItem != null) {
          // Exists only locally
          merged[id] = localItem;
          await remoteService!.save(localItem);
          logger.i('Synced to REMOTE: New $typeName with ID $id from LOCAL');
        } else if (remoteItem != null) {
          // Exists only remotely
          merged[id] = remoteItem;
          await localService.save(remoteItem);
          logger.i('Synced to LOCAL: New $typeName with ID $id from REMOTE');
        }
      }

      final finalList = merged.values.toList();
      logger.i('SaveManager: Sync complete. Returning ${finalList.length} items of type $typeName.');
      return finalList;
    }

    return [];
  }

  Future<void> delete(dynamic id) async {
    final typeName = T.toString();

    logger.d('SaveManager: Deleting item of type $typeName with ID $id (mode: ${saveMode.name})');

    if (saveMode == SaveMode.local) {
      await localService.delete(id);
      logger.i('SaveManager: Deleted $typeName with ID $id from LOCAL.');
    } else if (saveMode == SaveMode.remote) {
      final localDeleteFuture = localService.delete(id);
      final remoteDeleteFuture = remoteService!.delete(id);

      await Future.wait([localDeleteFuture, remoteDeleteFuture]);
      logger.i('SaveManager: Deleted $typeName with ID $id from LOCAL and REMOTE.');
    }
  }
}
