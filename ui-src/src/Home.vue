<template>
  <!-- 主体列表 -->
  <van-empty v-show="!moduleInfo.serviceState" image="network" :description="t('common.service_no_run')">
    <van-button round type="primary" class="bottom-button" @click="startService">{{
      t('common.service_start') }}</van-button>
  </van-empty>
  <van-field v-model="runModeName" is-link readonly name="picker" :label="$t('common.run_mode')"
    :placeholder="t('network.default_run_mode_tips')" @click="showRunModePicker = true"
    :disabled="moduleInfo.serviceState" />
  <van-popup v-model:show="showRunModePicker" destroy-on-close position="bottom">
    <van-picker :columns="runModeOption" v-model="selectedRunModeValues" @confirm="onRunModeConfirm"
      @cancel="showRunModePicker = false" />
  </van-popup>
  <div v-show="commandObj.runMode == 'command'">
    <van-cell-group inset :title="t('common.base_settings')">
      <van-field v-model="commandObj.networkName" name="networkName" :label="t('network.networkName')"
        :placeholder="t('network.networkName')" :disabled="moduleInfo.serviceState" required
        :rules="[{ required: true, message: t('network.networkNameTips') }]" />
      <van-field v-model="commandObj.networkPassWd" :label="t('network.network_secret')" right-icon="warning-o"
        type="password" :disabled="moduleInfo.serviceState" @click-right-icon="showPassword" required />
      <van-field name="switch" :label="t('network.virtual_ipv4_dhcp')" input-align="right">
        <template #input>
          <van-switch v-model="commandObj.dhcpEnable" :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>
      <van-field v-model="commandObj.virtual_ipv4" :label="t('network.virtual_ipv4')" placeholder="10.0.0.1/24"
        :rules="[{ validator: validatorMessage }]" :disabled="commandObj.dhcpEnable" />
      <van-field v-model="commandObj.peer_urls" name="" :label="t('network.peer_urls')"
        placeholder="tcp://public.easytier.top:11010" :rules="[{ validator: validatorMessage }]"
        :disabled="moduleInfo.serviceState" />
    </van-cell-group>
    <van-cell-group inset :title="t('common.advanced_settings')">
      <van-field v-model="commandObj.proxy_cidrs" :label="t('network.proxy_cidrs')" name="proxy_cidrs"
        placeholder="192.168.0.0/24" :disabled="moduleInfo.serviceState" :rules="[{ validator: validatorMessage }]" />
      <van-field v-model="listen" is-link readonly name="picker" :label="t('network.listenPort')" placeholder="不监听"
        :disabled="moduleInfo.serviceState" @click="showPicker2 = true" />
      <van-popup v-model:show="showPicker2" destroy-on-close position="bottom">
        <van-picker :columns="listenOption" v-model="selectedListenValues" @confirm="onListenConfirm"
          @cancel="showPicker2 = false" />
      </van-popup>
      <van-field v-model="commandObj.hostName" name="hostName" :label="t('network.hostName')"
        :placeholder="t('network.hostName')" />
      <van-field name="checkboxGroup" :label="t('network.flags_switch')" :disabled="moduleInfo.serviceState">
        <template #input>
          <van-checkbox-group v-model="checked" direction="horizontal" shape="square" @change="checkAllChange">
            <van-space direction="vertical" fill>
              <van-checkbox :name="item.name" v-for="(item, index) in textMap.advanced" :key="index">
                <template #default>
                  <van-cell :title="item.title" :label="item.label">
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
        <van-picker :columns="compressionAlgorithmOption" v-model="selectedCompressionAlgorithmValues"
          @confirm="onCompressionAlgorithmConfirm" @cancel="showCompressionAlgorithmPicker = false" />
      </van-popup>

      <van-field v-model="loggin" is-link readonly name="picker" :label="t('common.logging')"
        :placeholder="t('common.close')" @click="showLogginPicker = true" />
      <van-popup v-model:show="showLogginPicker" destroy-on-close position="bottom">
        <van-picker :columns="logLevel" v-model="selectedLogginValues" @confirm="onLogginConfirm"
          @cancel="showLogginPicker = false" />
      </van-popup>
      <van-field v-model="commandObj.rpcPort" name="rpcPort" :label="t('network.rpc_port')" placeholder="15888"
        :rules="[{ validator: validatorMessage }]" />
      <van-field v-model="commandObj.tunName" name="tunName" :label="t('network.tun_name')" placeholder="留空自动生成" />
    </van-cell-group>
  </div>
  <div v-show="commandObj.runMode == 'web'">
    <van-cell-group inset :title="t('network.webMode')">
      <van-field v-model="value3" :label="t('network.webServer')" placeholder="" :disabled="moduleInfo.serviceState"
        :rules="[{ validator: validatorMessage }]" />
      <van-field name="switch" :label="t('network.local_web')" input-align="right">
        <template #input>
          <van-switch @change="moduleInfo.changePrivateDeployment" v-model="moduleInfo.privateDeployment"
            :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>
    </van-cell-group>
  </div>
  <div v-show="commandObj.runMode == 'file'">
    <van-cell-group inset :title="t('network.fileMode')">
      <van-cell center title="操作">
        <template #right-icon>
          <van-button type="primary" size="mini" icon="replay" plain
            @click="router.push('/manage/config')">配置助手</van-button>
          <van-button type="primary" size="mini" icon="replay" plain @click="reload()">重载配置</van-button>
          <van-button type="primary" size="mini" icon="plus" plain @click="update()">保存配置</van-button>
        </template>
      </van-cell>
      <codemirror v-model:value="code" :style="{ height: '50vh' }" :tabSize="2" placeholder="Toml"
        :extensions="extensions" :autofocus="true" :indent-with-tab="true" />
    </van-cell-group>
  </div>

</template>
<script setup>
const props = defineProps({
  theme: Boolean
})
//接收父组件传来的值
console.info(`theme:${props.theme}`)
import { onMounted, ref, computed } from 'vue';
import { MODDIR, ETPATH, execCmd, getCorePath } from './tools'
import { useModuleInfoStore } from './stores/status'
import { useI18n } from './locales'; // 导入所有翻译信息
import { Codemirror } from "vue-codemirror";
import { StreamLanguage } from "@codemirror/language"
import { toml } from "@codemirror/legacy-modes/mode/toml"
import { oneDark } from "@codemirror/theme-one-dark"

const router = useRouter()
const { t } = useI18n();
const moduleInfo = useModuleInfoStore();
const checked = ref([]);
const code = ref('')
const chosenAddressId = ref('1');
const listen = ref('');
const loading = ref(false);
const dhcpEnable = ref(false);
const readonly = ref(false);
const ready = ref(false);
const items = reactive([]);
const show = ref(false);


const commandObj = ref({
  'networkName': '',
  'networkPassWd': '',
  'dhcpEnable': true,
  'virtual_ipv4': '10.0.0.2/24',
  'peer_urls': 'tcp://public.easytier.top:11010',
  'proxy_cidrs': '',
  'listen': false,
  'hostName': 'easytierForKSU',
  'compressionAlgorithm': 'none',
  'logLevel': 'off',
  'rpcPort': 15888,
  'tunName': '',
  'advance': []
});
const textMap = {
  "runModeOption": {
    "command": '命令行',
    "file": '配置文件',
    "web": 'WEB配置'
  },
  "listenOption": {
    "true": '启用监听',
    "false": '不监听'
  },
  "compressionAlgorithmOption": {
    "none": '默认',
    "zstd": 'zstd'
  },
  "logLevel": {
    "off": '关闭',
    "warn": '警告',
    "info": '信息',
    "debug": '调试',
    "trace": '跟踪'
  },
  "advanced": [
    {
      "name": "disableEncryption",
      "title": t('network.disableEncryption'),
      "label": "禁用对等节点通信的加密，若关闭加密则其他节点也必须关闭加密"
    },
    {
      "name": "disableP2P",
      "title": t('network.disable_p2p'),
      "label": "禁用P2P通信，只通过-p指定的节点转发数据包"
    },
    {
      "name": "listenIPv6",
      "title": t('network.listenIPv6'),
      "label": "同时监听IPv6"
    },
    {
      "name": "enableKCPProxy",
      "title": t('network.enable_kcp_proxy'),
      "label": "将TCP流量转为 KCP 流量，降低传输延迟，提升传输速度"
    },
    {
      "name": "disableUdpHolePunching",
      "title": t('network.disableUdpHolePunching'),
      "label": "禁用UDP打洞功能"
    },
    {
      "name": "disableKCPInput",
      "title": t('network.disable_kcp_input'),
      "label": "不允许其他节点使用 KCP 代理 TCP 流到此节点。开启 KCP 代理的节点访问此节点时，依然使用原始"
    },
    {
      "name": "noTun",
      "title": t('network.no_tun'),
      "label": "不创建TUN设备，可以使用子网代理访问节点"
    },
    {
      "name": "multiThread",
      "title": t('network.multiThread'),
      "label": "使用多线程运行时，默认为单线程"
    },
    {
      "name": "latencyFirst",
      "title": t('network.latencyFirst'),
      "label": "延迟优先模式，将尝试使用最低延迟路径转发流量，默认使用最短路径"
    },
    {
      "name": "useSmoltcp",
      "title": t('network.use_smoltcp'),
      "label": "为子网代理启用smoltcp堆栈"
    }
  ]

}
let runModeOption = [];
let listenOption = [];
let compressionAlgorithmOption = [];
let logLevel = [];

const selectedRunModeValues = ref(['command']);
const selectedListenValues = ref(['false']);
// const selectedValues = ref(['command']);
const checkAllChange = (val) => {
  console.info(checked)
  console.info(val)
  commandObj.value.advance = checked.value;
}

const validatorMessage = (val) => `${val} 不合法，请重新输入`;
const showRunModePicker = ref(false);
const showCompressionAlgorithmPicker = ref(false);
const showLogginPicker = ref(false);
const showPicker2 = ref(false);
const runModeName = ref('');
const compressionAlgorithm = ref('');
const value3 = ref('');
const loggin = ref('');
const commandArgs = ref([]);

// ======== method=========
const fillOptions = () => {
  for (const key in textMap) {
    const obj = textMap[key];
    for (const k in obj) {
      if (key == 'runModeOption') {
        runModeOption.push({ text: obj[k], value: k });
      } else if (key == 'listenOption') {
        listenOption.push({ text: obj[k], value: k });
      } else if (key == 'compressionAlgorithmOption') {
        compressionAlgorithmOption.push({ text: obj[k], value: k });
      } else if (key == 'logLevel') {
        logLevel.push({ text: obj[k], value: k });
      }
    }
  }
}
const extensions = computed(() => {
  const result = [StreamLanguage.define(toml)]
  if (!props.theme) {
    result.push(oneDark)
  }
  return result
})
onMounted(() => {
  console.info(moduleInfo.serviceState)
  fillOptions();
  init()
})

const onRunModeConfirm = ({ selectedValues }) => {
  commandObj.value.runMode = selectedValues.join(',');
  runModeName.value = textMap.runModeOption[selectedValues.join(',')];
  showRunModePicker.value = false;
  moduleInfo.runMode = selectedValues.join(',');
};
const onListenConfirm = ({ selectedValues }) => {
  commandObj.value.listen = selectedValues.join(',');
  listen.value = textMap.listenOption[selectedValues.join(',')];
  showPicker2.value = false;
};
const onLogginConfirm = ({ selectedValues }) => {
  commandObj.value.logLevel = selectedValues.join(',');
  loggin.value = textMap.logLevel[selectedValues.join(',')];
  showLogginPicker.value = false;
};
const onCompressionAlgorithmConfirm = ({ selectedValues }) => {
  commandObj.value.compressionAlgorithm = selectedValues.join(',');
  compressionAlgorithm.value = textMap.compressionAlgorithmOption[selectedValues.join(',')];
  showCompressionAlgorithmPicker.value = false;
};


const startService = () => {
  debugger

  switch (commandObj.value.runMode) {
    case "command":
      // 核心代码
      let cmd = `${getCorePath()} --network-name ${commandObj.value.networkName} --network-secret ${commandObj.value.networkPassWd} `
      // DHCP服务
      if (dhcpEnable.value == true) {
        cmd += "-d"
      }
      break;
    case "file":
      break;
    case "web":
      break;
    default:

      break;
  }
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
const getList = () => {
  if (!moduleInfo.getServiceState()) {
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


</script>

<style>
.full-button {
  height: 100%;
}
</style>