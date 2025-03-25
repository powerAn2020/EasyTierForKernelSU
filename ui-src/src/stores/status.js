import { defineStore } from 'pinia';

export const useModuleInfoStore = defineStore('moduleInfo', {
  state: () => ({
    serviceState: false,
    privateDeployment:false,
    runMode:'command'
  }),
  getters: {
    getServiceState(state) {
      return state.serviceState;
    }
  },
  actions: {
    changeServiceState(state) {
      this.serviceState = state;
    },
    changePrivateDeployment(state) {
      this.privateDeployment = state;
    },
    changeRunMode(state) {
      this.privateDeployment = state;
    }
  }
});