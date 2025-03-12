import { defineStore } from 'pinia';

export const useModuleInfoStore = defineStore('moduleInfo', {
  state: () => ({
    serviceState: false
  }),
  getters: {
    getServiceState(state) {
      return state.serviceState;
    }
  },
  actions: {
    changeServiceState(state) {
      this.serviceState = state;
    }
  }
});