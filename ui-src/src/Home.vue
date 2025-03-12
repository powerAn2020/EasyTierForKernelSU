<template>
  <div>
    <!-- 主体列表 -->
    <van-empty v-show="!moduleInfo.status" image="network" :description="t('common.service_no_run')">
      <van-button round type="primary" class="bottom-button" @click="startService">{{
        t('common.service_start') }}</van-button>
    </van-empty>
    <van-cell-group inset :title="t('common.base_settings')">
      <van-field v-model="runMode" is-link readonly name="picker" :label="$t('common.run_mode')"
        :placeholder="t('network.default_run_mode_tips')" @click="showRunModePicker = true"
        :disabled="moduleInfo.status" />
      <van-popup v-model:show="showRunModePicker" destroy-on-close position="bottom">
        <van-picker :columns="runModeOption" v-model="selectedValues" @confirm="onConfirm"
          @cancel="showRunModePicker = false" />
      </van-popup>
      <van-field v-model="networkId" name="networkName" :label="t('network.networkName')"
        :placeholder="t('network.networkName')" :disabled="moduleInfo.status"
        :rules="[{ required: true, message: t('network.networkNameTips') }]" />
      <van-field v-model="networkPassWd" :label="t('network.network_secret')" right-icon="warning-o" type="password"
        :disabled="moduleInfo.status" @click-right-icon="showPassword" />
      <van-field name="switch" :label="t('network.virtual_ipv4_dhcp')">
        <template #input>
          <van-switch v-model="checked" :disabled="moduleInfo.status" />
        </template>
      </van-field>
      <van-field v-model="value3" :name="virtual_ipv4" :label="t('network.virtual_ipv4')" placeholder="10.0.0.1/24"
        :rules="[{ validator: validatorMessage }]" :disabled="moduleInfo.status" />
      <van-field v-model="value3" name="" :label="t('network.peer_urls')" placeholder="tcp://public.easytier.top:11010"
        :rules="[{ validator: validatorMessage }]" :disabled="moduleInfo.status" />
    </van-cell-group>
    <van-cell-group inset :title="t('common.advanced_settings')">
      <van-field v-model="value3" :label="t('network.proxy_cidrs')" name="proxy_cidrs" placeholder="192.168.0.0/24"
        :disabled="moduleInfo.status" :rules="[{ validator: validatorMessage }]" />
      <van-field v-model="result" is-link readonly name="picker" :label="t('network.listenPort')" placeholder="不监听"
        :disabled="moduleInfo.status" @click="showPicker2 = true" />
      <van-popup v-model:show="showPicker2" destroy-on-close position="bottom">
        <van-picker :columns="columns2" v-model="selectedValues" @confirm="onConfirm" @cancel="showPicker2 = false" />
      </van-popup>
      <!-- <van-field name="switch" label="同时监听IPV6">
      <template #input>
        <van-switch v-model="checked" />
      </template>
    </van-field> -->
      <van-field v-model="value3" name="hostName" :label="t('network.hostName')" :placeholder="t('network.hostName')" />
      <van-field name="checkboxGroup" :label="t('network.flags_switch')" :disabled="moduleInfo.status">
        <template #input>
          <van-checkbox-group v-model="checked" direction="horizontal" shape="square">
            <van-space direction="vertical" fill>
              <van-checkbox name="f">
                <template #default>
                  <van-cell :title="t('network.disableEncryption')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="c">
                <template #default>
                  <van-cell :title="t('network.disable_p2p')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="a">
                <template #default>
                  <van-cell :title="t('network.listenIPv6')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="b">
                <template #default>
                  <van-cell :title="t('network.enable_kcp_proxy')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="a">
                <template #default>
                  <van-cell :title="t('network.disableUdpHolePunching')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="d">
                <template #default>
                  <van-cell :title="t('network.disable_kcp_input')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="e">
                <template #default>
                  <van-cell :title="t('network.no_tun')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="g">
                <template #default>
                  <van-cell :title="t('network.multiThread')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="h">
                <template #default>
                  <van-cell :title="t('network.latencyFirst')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
              <van-checkbox name="i">
                <template #default>
                  <van-cell :title="t('network.use_smoltcp')" label="描述信息">
                  </van-cell>
                </template>
              </van-checkbox>
            </van-space>
          </van-checkbox-group>
        </template>
      </van-field>
      <van-field v-model="compressionAlgorithm" is-link readonly name="picker"
        :label="t('network.compressionAlgorithm')" :placeholder="t('common.default')"
        @click="showCompressionAlgorithmPicker = true" />
      <van-popup v-model:show="showCompressionAlgorithmPicker" destroy-on-close position="bottom">
        <van-picker :columns="compressionAlgorithmOption" v-model="selectedValues" @confirm="onConfirm"
          @cancel="showCompressionAlgorithmPicker = false" />
      </van-popup>

      <van-field v-model="loggin" is-link readonly name="picker" :label="t('common.logging')"
        :placeholder="t('common.close')" @click="showLogginPicker = true" />
      <van-popup v-model:show="showLogginPicker" destroy-on-close position="bottom">
        <van-picker :columns="logLevel" v-model="selectedValues" @confirm="onConfirm" @cancel="showLogginPicker = false" />
      </van-popup>
      <van-field v-model="value3" name="rpcPort" :label="t('network.rpc_port')" placeholder="15888"
        :rules="[{ validator: validatorMessage }]" />
      <van-field v-model="value3" name="tunName" :label="t('network.tun_name')" placeholder="留空自动生成" />
    </van-cell-group>
  </div>


</template>

<script setup>
defineProps(["theme"]);//接收父组件传来的值
import { onMounted } from 'vue';
import { JsonViewer } from "vue3-json-viewer"
import { MODDIR, ZTPATH, execCmd } from './tools'
import { useModuleInfoStore } from './stores/status'
import { useI18n } from './locales'; // 导入所有翻译信息
const { t } = useI18n();
const moduleInfo = useModuleInfoStore();
const checked = ref([]);

const chosenAddressId = ref('1');
const networkId = ref('');
const networkPassWd = ref('');
const loading = ref(false);
const readonly = ref(false);
const show = ref(false);
const activeNames = ref(null);
const ready = ref(false);
const items = reactive([]);
const addOrUpdate = ref(source());
function source() {
  return {
    "allowDNS": false,
    "allowDefault": false,
    "allowManaged": true,
    "allowGlobal": false,
    "name": '',
    "id": ''
  };
}
const runModeOption = [
  { text: '命令行模式', value: 'command' },
  { text: '配置文件', value: 'file' },
  { text: 'WEB配置', value: 'web' }
];
const columns2 = [
  { text: '启用监听', value: 'command' },
  { text: '不监听', value: 'file' },
];
const compressionAlgorithmOption = [
  { text: '默认', value: 'none' },
  { text: 'zstd', value: 'zstd' },
];
const logLevel = [
  { text: '关闭', value: 'off' },
  { text: '警告', value: 'warn' },
  { text: '信息', value: 'info' },
  { text: '调试', value: 'debug' },
  { text: '跟踪', value: 'trace' },
];
const selectedValues = ref(['command']);


const validatorMessage = (val) => `${val} 不合法，请重新输入`;
const showPicker = ref(false);
const showRunModePicker = ref(false);
const showCompressionAlgorithmPicker = ref(false);
const showLogginPicker = ref(false);
const showPicker2 = ref(false);
const runMode = ref('');
const compressionAlgorithm = ref('');
const value3 = ref('');
const loggin = ref('');
// ======== method=========
onMounted(() => {

})
const onConfirm = ({ selectedValues }) => {
  showToast(`当前值: ${selectedValues.join(',')}`);
  runMode.value = selectedValues.join(',');
};
const onChange = ({ selectedValues }) => {
  showToast(`当前值: ${selectedValues.join(',')}`);
};
const onCancel = () => showToast('取消');

const reset = () => {
  addOrUpdate.value = source()
  info = addOrUpdate.value;
}
let info = addOrUpdate.value // Js里操作只操作 info 就可以不用 infoRef.value 了
const onRefresh = () => {
  getList();
  setTimeout(() => {
    loading.value = false;
  }, 50);
};
const startService = () => {
  execCmd(`rm ${ZTPATH}/state/disable`).then(v => {
    setTimeout(() => {
      showToast(t('common.operation_success'));
      ready.value = true;
      window.location.reload();
    }, 50);
  })
}
const startServiceConfirm = () => {
  showConfirmDialog({
    title: t('common.ask_service_start'),
  })
    .then(() => {
      startService()
    })
    .catch(() => resolve(true));

}
//新增或修改
const newAdd = (index) => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  show.value = true;
  if (typeof (index) !== 'undefined') {
    //修改回显
    readonly.value = true;
    const editObj = JSON.parse(JSON.stringify(items[index]));
    info.allowDNS = editObj.allowDNS,
      info.allowDefault = editObj.allowDefault,
      info.allowManaged = editObj.allowManaged,
      info.allowGlobal = editObj.allowGlobal,
      info.name = editObj.name,
      info.id = editObj.id
  } else {
    readonly.value = false;
    reset()
  }
  chosenAddressId.value = index;
}
const changeStatus = (index) => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  let status = items[index];
  //点击禁用
  if (typeof (status.enable) == 'undefined' || status.enable === 'true') {
    status.enable = 'false';
    leaveApi(status)
  } else {
    status.enable = 'true';
    //点击启用
    joinApi(status)
    let leaveNetwork = JSON.parse(localStorage.getItem('EasytierForKSU.leaveNetwork'));
    const nleaveNetwork = leaveNetwork.filter(item => item.id !== status.id)
    localStorage.setItem("EasytierForKSU.leaveNetwork", JSON.stringify(nleaveNetwork));
  }
}
const delNode = (index) => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  showConfirmDialog({
    title: t('home.leave_confirm'),
  })
    .then(() => {
      let leaveNetwork = JSON.parse(localStorage.getItem('EasytierForKSU.leaveNetwork'));
      let status = items[index];
      items.splice(index, 1)
      leaveApi(status)
      if (leaveNetwork.length > 0) {
        const nleaveNetwork = leaveNetwork.filter(item => item.id !== status.id);
        localStorage.setItem("EasytierForKSU.leaveNetwork", JSON.stringify(nleaveNetwork));
      }
      return true;
    })
    .catch(() => resolve(true));
}
const joinApi = (info) => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  const postData = JSON.stringify(info)
  execCmd(`sh ${MODDIR}/api.sh local network join ${info.id} '${postData}'`).then(v => {
    try {
      const statusObj = JSON.parse(v);
      console.info(statusObj);
      showToast(t('network.operation_success'));
      setTimeout(() => {
        window.location.reload();
      }, 50);
    } catch (error) {
      showDialog({
        title: t('network.operation_fail'),
        message: v
      }).then(() => {
        // on close
      });
    }

  });
}
const leaveApi = (info) => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  execCmd(`sh ${MODDIR}/api.sh local network leave ${info.id}`).then(v => {
    try {
      let leaveNetwork = JSON.parse(localStorage.getItem('EasytierForKSU.leaveNetwork'));
      const statusObj = JSON.parse(v);
      console.info(statusObj);
      leaveNetwork.push(info)
      localStorage.setItem("EasytierForKSU.leaveNetwork", JSON.stringify(leaveNetwork));
      // showToast('完成,即将重载列表');
      // setTimeout(() => {
      //   window.location.reload();
      // }, 50);
    } catch (error) {
      console.error(v);
      showDialog({
        title: t('network.operation_fail'),
        message: v
      }).then(() => {
        // on close
      });
    }
  });
}
const getList = () => {
  if (!moduleInfo.getServiceState) {
    startServiceConfirm()
    return;
  }
  execCmd(`sh ${MODDIR}/api.sh local network list`).then(v => {
    items.length = 0;
    if (v !== "") {
      const statusObj = JSON.parse(v);
      if (statusObj.length > 0) {
        let leaveNetwork = JSON.parse(localStorage.getItem('EasytierForKSU.leaveNetwork'));
        if (leaveNetwork) {
          items.push(...leaveNetwork)
        }
        items.push(...statusObj)
      } else if (items.length == 0) {
        console.info(t('home.noNetwork_tips'))
      }
    }
  });
}
const addOrUpdateBtn = (action) =>
  new Promise((resolve) => {
    if (action === 'confirm') {
      // items.push(info);
      joinApi(info)
      setTimeout(() => {
        resolve(true)
      }, 50);
    } else if (action === 'cancel') {
      resolve(true);
      // reset();
    }
  });

const init = () => {
  console.info('init')
  showLoadingToast({
    duration: 0,
    message: '',
    forbidClick: true,
    loadingType: 'spinner',
  });
  let leaveNetwork = localStorage.getItem("EasytierForKSU.leaveNetwork");
  if (typeof leaveNetwork == "undefined" || leaveNetwork == null) {
    leaveNetwork = [];
    localStorage.setItem("EasytierForKSU.leaveNetwork", JSON.stringify(leaveNetwork));
  } else {
    leaveNetwork = JSON.parse(leaveNetwork);
  }
  setTimeout(() => {
    execCmd(`sh ${MODDIR}/zerotier.sh status`).then(v => {
      const statusObj = JSON.parse(v);
      if (statusObj.enable == "") {
        ready.value = false;
        moduleInfo.changeServiceState(false);
        // startServiceConfirm()
      } else {
        ready.value = true;
        moduleInfo.changeServiceState(true);
        getList();
      }
    });
    closeToast()
  }, 1000)
}
init()

//加载路由并配置防火墙
// const loadRouter=()=>{
//   const defaultRoterMode=localStorage.getItem('EasytierForKSU.defaultRoterMode')
//   execCmd(`sh ${MODDIR}/api.sh local router ${defaultRoterMode} `).then(v => {
//   })
// }
defineExpose({ newAdd });

</script>

<style>
.full-button {
  height: 100%;
}
</style>