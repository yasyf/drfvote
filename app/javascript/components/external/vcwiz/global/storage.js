import {StoragePrefix} from './constants.js.erb';

export const storageKey = (key) => `${StoragePrefix}::${key}`;

const StorageMock = {
  get: _.noop,
  set: _.noop,
  getExpr: _.noop,
  setExpr: _.noop,
  clearExpr: _.noop,
};

const Storage = {
  _get: key => JSON.parse(window.sessionStorage.getItem(key)),
  get: key => Storage._get(storageKey(key)),
  _remove: key => window.sessionStorage.setItem(key, null),
  remove: key =>  Storage._remove(storageKey(key)),
  _set: (key, value) => window.sessionStorage.setItem(key, JSON.stringify(value)),
  set: (key, value) => Storage._set(storageKey(key), value),
  getExpr: key => {
    const got = Storage.get(key);
    if (got === null || got === undefined || got.value === undefined) {
      return null;
    }
    const {value, expr} = got;
    if (expr > Date.now()) {
      return value;
    } else {
      Storage.remove(key);
      return null;
    }
  },
  setExpr: (key, value, expr) => {
    try {
      Storage.set(key, {value, expr: Date.now() + (expr * 1000)});
      return true;
    } catch (e) {
      Storage.clearExpr();
      return false;
    }
  },
  clearExpr: () => {
    Object.keys(window.sessionStorage).forEach(key => {
      const got = Storage._get(key);
      if (got && got.expr) {
        Storage._remove(key);
      }
    });
  },
};

export default window.sessionStorage ? Storage : StorageMock;