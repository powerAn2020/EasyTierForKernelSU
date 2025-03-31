<template>
  <!-- 主体列表 -->
  <van-empty image="network" :description="moduleInfo.serviceState?t('common.service_running'):t('common.service_no_run')">
    <van-button round type="primary" class="bottom-button" @click="startService" :color="moduleInfo.serviceState?'linear-gradient(to right, #ff6034, #ee0a24)':'#1989FA'">
      {{!moduleInfo.serviceState?t('common.service_start'):t('common.service_stop') }}</van-button>
  </van-empty>
  <van-field v-model="runModeName" is-link readonly :label="$t('common.run_mode')"
    :placeholder="t('network.default_run_mode_tips')" @click="showRunModePicker = true"
    :disabled="moduleInfo.serviceState" />
  <van-popup v-model:show="showRunModePicker" destroy-on-close position="bottom">
    <van-picker :columns="runModeOption" v-model="selectedRunModeValues" @confirm="onRunModeConfirm"
      @cancel="showRunModePicker = false" />
  </van-popup>
  <div v-show="commandObj.runMode == 'command'">
    <van-cell-group inset :title="t('common.base_settings')">
      <van-field v-model="commandObj.networkName" :label="t('network.networkName')" :disabled="moduleInfo.serviceState"
        required />
      <van-field v-model="commandObj.networkPassWd" :label="t('network.network_secret')"
        :disabled="moduleInfo.serviceState" required />
      <van-field :label="t('network.virtual_ipv4_dhcp')" input-align="right">
        <template #input>
          <van-switch v-model="commandObj.dhcpEnable" :disabled="moduleInfo.serviceState" />
        </template>
      </van-field>
      <van-field v-model="commandObj.virtual_ipv4" :label="t('network.virtual_ipv4')" placeholder="10.0.0.1/24"
        :rules="[{ validator: validatorMessage }]" :disabled="commandObj.dhcpEnable" />
      <van-field v-model="commandObj.peer_urls" :label="t('network.peer_urls')" placeholder="初始连接的对等节点, -p 参数"
        :rules="[{ validator: validatorMessage }]" :disabled="moduleInfo.serviceState" />
    </van-cell-group>
    <van-cell-group inset :title="t('common.advanced_settings')">
      <van-field v-model="commandObj.external_node" :label="t('network.external_node')"
        placeholder="使用公共共享节点来发现对等节点, -e 参数" :rules="[{ validator: validatorMessage }]"
        :disabled="moduleInfo.serviceState" />
      <van-field v-model="commandObj.hostName" :label="t('network.hostName')" :placeholder="t('network.hostName')" :disabled="moduleInfo.serviceState"/>

      <van-collapse v-model="activeNames">
        <van-collapse-item :title="t('network.proxy_cidrs')" name="1">
          <template #value>
            <van-tag plain type="primary" v-for="(route2, ridx2) in commandObj.proxy_cidrs" :key="ridx2">
              {{ route2 }}
            </van-tag>
            <van-tag plain type="primary" v-show="commandObj.proxy_cidrs.length === 0">
              {{ t('network.addSubRouteTips') }}
            </van-tag>

          </template>
          <van-cell title="" center>
            <template #value>
              <van-button type="success" size="small" @click="commandObj.proxy_cidrs.push('')" :disabled="moduleInfo.serviceState">
                {{ t('networkDetail.addRouteRule') }}
              </van-button>
            </template>
          </van-cell>
          <van-field v-for="(route, ridx) in commandObj.proxy_cidrs" :key="ridx" v-model="commandObj.proxy_cidrs[ridx]"
            clearable placeholder="192.168.0.0/23"><template #button>
              <van-icon name="delete-o" color="#1989fa" size="1.2rem" @click="commandObj.proxy_cidrs.splice(ridx, 1)" />
            </template></van-field>
        </van-collapse-item>
        <van-collapse-item :title="t('network.flags_switch')" name="2">
          <van-checkbox-group v-model="checked" direction="horizontal" shape="square" @change="checkAllChange">
            <van-space direction="vertical" fill>
              <van-checkbox :disabled="moduleInfo.serviceState" label-position="left" :name="item.name" v-for="(item, index) in textMap.advanced" :key="index">
                <template #default>
                  <van-cell :title="item.title" :label="item.label">
                  </van-cell>
                </template>
              </van-checkbox>
            </van-space>
          </van-checkbox-group>
        </van-collapse-item>
      </van-collapse>

      <van-popup v-model:show="showPicker2" destroy-on-close position="bottom">
        <van-picker :columns="listenOption" v-model="selectedListenValues" @confirm="onListenConfirm"
          @cancel="showPicker2 = false" />
      </van-popup>
      <van-field v-model="compressionAlgorithm" is-link readonly :label="t('network.compressionAlgorithm')" :disabled="moduleInfo.serviceState"
        :placeholder="t('common.default')" @click="showCompressionAlgorithmPicker = true" />
      <van-popup v-model:show="showCompressionAlgorithmPicker" destroy-on-close position="bottom">
        <van-picker :columns="compressionAlgorithmOption" v-model="selectedCompressionAlgorithmValues"
          @confirm="onCompressionAlgorithmConfirm" @cancel="showCompressionAlgorithmPicker = false" />
      </van-popup>

      <van-field v-model="loggin" is-link readonly :label="t('common.logging')" :placeholder="t('common.close')" :disabled="moduleInfo.serviceState"
        @click="showLogginPicker = true" />
      <van-popup v-model:show="showLogginPicker" destroy-on-close position="bottom">
        <van-picker :columns="logLevel" v-model="selectedLogginValues" @confirm="onLogginConfirm"
          @cancel="showLogginPicker = false" />
      </van-popup>
      <van-field v-model="commandObj.rpcPort" :label="t('network.rpc_port')" placeholder="15888" type="digit" :disabled="moduleInfo.serviceState"/>
      <van-field v-model="commandObj.tunName" :label="t('network.tun_name')" placeholder="留空自动生成" :disabled="moduleInfo.serviceState"/>
      <van-field v-model="listen" is-link readonly :label="t('network.listenPort')" placeholder="不监听"
        :disabled="moduleInfo.serviceState" @click="showPicker2 = true" />
    </van-cell-group>
  </div>
  <div v-show="commandObj.runMode == 'web'">
    <van-cell-group inset :title="t('network.webMode')">
      <van-field v-model="commandObj.webServer" :label="t('network.webServer')" placeholder=""
        :disabled="moduleInfo.serviceState" :rules="[{ validator: validatorMessage }]" />
      <van-field :label="t('network.local_web')" input-align="right">
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
      <codemirror v-model:value="commandObj.conf" :style="{ height: '50vh' }" :tabSize="2" placeholder="Toml"
        :extensions="extensions" :autofocus="true" :indent-with-tab="true" :disabled="moduleInfo.serviceState" />
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
import { MODDIR, ETPATH, execCmd, getCorePath, isValidIpv4Subnet, isValidPort, isEmpty, logDir } from './tools'
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
const listen = ref('');
const dhcpEnable = ref(false);
const ready = ref(false);
const activeNames = ref(['']);
let runModeOption = [];
let listenOption = [];
let compressionAlgorithmOption = [];
let logLevel = [];

const selectedRunModeValues = ref(['command']);
const selectedListenValues = ref(['false']);

const validatorMessage = (val) => `${val} 不合法，请重新输入`;
const showRunModePicker = ref(false);
const showCompressionAlgorithmPicker = ref(false);
const showLogginPicker = ref(false);
const showPicker2 = ref(false);
const runModeName = ref('');
const compressionAlgorithm = ref('');
const loggin = ref('');

const commandObj = ref({
  'runMode': 'command',
  'networkName': '',
  'networkPassWd': '',
  'dhcpEnable': true,
  'virtual_ipv4': '10.0.0.2/24',
  'peer_urls': 'tcp://public.easytier.top:11010',
  'external_node': '',
  'proxy_cidrs': [],
  'listen': false,
  'hostName': 'easytierForKSU',
  'compressionAlgorithm': 'none',
  'logLevel': 'off',
  'rpcPort': 15888,
  'tunName': '',
  'advance': [],
  'conf': '',
  'webServer': '',
  'privateDeployment': false
});
// TODO 国际化
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
    // {
    //   "name": "listenIPv6",
    //   "title": t('network.listenIPv6'),
    //   "label": "同时监听IPv6"
    // },
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
// ======== method=========
const checkAllChange = (val) => {
  commandObj.value.advance = checked.value;
}
const fillOptions = () => {
  console.info('填充参数')
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
  runModeName.value = textMap.runModeOption[commandObj.value.runMode];
  listen.value = textMap.listenOption[commandObj.value.listen];
  compressionAlgorithm.value = textMap.compressionAlgorithmOption[commandObj.value.compressionAlgorithm];
  loggin.value = textMap.logLevel[commandObj.value.logLevel];
}
const extensions = computed(() => {
  const result = [StreamLanguage.define(toml)]
  if (!props.theme) {
    result.push(oneDark)
  }
  return result
})
onMounted(() => {
  console.info(`服务状态：moduleInfo.serviceState`)
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
/**
 * 检查已填报的内容
 */
const checkContent = (runMode) => {
  let commandArgs = `${getCorePath()} `
  if (runMode === 'command') {
    //设置网络名称
    if (isEmpty(commandObj.value.networkName)) {
      showNotify({
        type: 'danger',
        message: t('network.networkName_empty')
      });
      return;
    } else {
      commandArgs += ` --network-name ${commandObj.value.networkName}`
    }
    //设置网络密码
    if (isEmpty(commandObj.value.networkPassWd)) {
      showNotify({
        type: 'warning',
        message: t('network.networkPassWd_empty_warn')
      });
    } else {
      commandArgs += ` --network-secret ${commandObj.value.networkPassWd}`
    }
    //DHCP和虚拟IP地址
    if (commandObj.value.dhcpEnable) {
      commandArgs += ' -d'
    } else if (!isEmpty(commandObj.value.virtual_ipv4) && !isValidIpv4Subnet(commandObj.value.virtual_ipv4)) {
      showNotify({
        type: 'danger',
        message: t('network.virtual_ipv4_error')
      });
      return;
    } else {
      commandArgs += ' -i ' + commandObj.value.virtual_ipv4
    }
    //对等节点
    if (!isEmpty(commandObj.value.peer_urls)) {
      commandArgs += ' -p ' + commandObj.value.peer_urls
    }

    //共享节点
    if (!isEmpty(commandObj.value.external_node)) {
      commandArgs += ' -e ' + commandObj.value.external_node
    }

    //子网代理
    // TODO 子网代理支持多个网段的，这里需要改
    if (commandObj.value.proxy_cidrs.length > 1) {
      for (let i = 0; i < commandObj.value.proxy_cidrs.length; i++) {
        if (isValidIpv4Subnet(commandObj.value.proxy_cidrs[i])) {
          showNotify({
            type: 'danger',
            message: t('network.proxy_cidrs_error')
          });
          return;
        } else {
          commandArgs += ` -n ${commandObj.value.proxy_cidrs[i]} `
        }
      }
    }
    //监听端口
    //TODO 监听端口的时候需要给出自定义端口选项
    if (commandObj.value.listen === 'true') {
      // 如果启用监听，使用默认端口
      commandArgs += ' -l '
    } else if (commandObj.value.listen === 'false') {
      // 不监听
      commandArgs += ' --no-listener'
    }
    //主机名
    if (!isEmpty(commandObj.value.hostName)) {
      commandArgs += ` --hostname ${commandObj.value.hostName} `
    }
    //压缩算法
    if (commandObj.value.compressionAlgorithm !== 'none') {
      commandArgs += ` --compression ${commandObj.value.compressionAlgorithm} `
    }
    // 日志级别
    if (!isEmpty(commandObj.value.logLevel)) {
      commandArgs += ` --file-log-level ${commandObj.value.logLevel} `
      commandArgs += ` --file-log-dir ${logDir} `
    }
    //RPC门户端口
    if (!isEmpty(commandObj.value.rpcPort)) {
      commandObj.value.rpcPort = 15888;
    }
    commandArgs += ` --rpc-portal ${commandObj.value.rpcPort} `
    //tun设备名称
    if (!isEmpty(commandObj.value.tunName)) {
      commandArgs += ` --dev-name ${commandObj.value.tunName} `
    }
    // advance
    if (commandObj.value.advance.length > 0) {
      commandObj.value.advance.forEach(item => {
        switch (item) {
          case "disableEncryption":
            commandArgs += ' --disable-encryption '
            break;
          case "disableP2P":
            commandArgs += ' --disable-p2p '
            break;
          // case "listenIPv6":
          //   commandArgs += ' --listen-ipv6 '
          //   break;
          case "enableKCPProxy":
            commandArgs += ' --enable-kcp-proxy '
            break;
          case "disableUdpHolePunching":
            commandArgs += ' --disable-udp-hole-punching '
            break;
          case "disableKCPInput":
            commandArgs += ' --disable-kcp-input '
            break;
          case "noTun":
            commandArgs += ' --no-tun '
            break;
          case "multiThread":
            commandArgs += ' --multi-thread '
            break;
          case "latencyFirst":
            commandArgs += ' --latency-first '
            break;
          case "useSmoltcp":
            commandArgs += ' --use-smoltcp '
            break;
          default:
            break;
        }
      });
    }
    return commandArgs;
  } else if (runMode === 'file') {
    if (isEmpty(commandObj.value.conf)) {
      showNotify({
        type: 'danger',
        message: t('network.conf_empty')
      });
      return;
    }
  } else if (runMode === 'web') {
    if (isEmpty(commandObj.value.webServer)) {
      showNotify({
        type: 'danger',
        message: t('network.webServer_empty')
      });
      return;
    }
  } else {
    showNotify({
      type: 'danger',
      message: t('network.runMode_error')
    });
    return;
  }

};// 启动服务
const startService = () => {
  moduleInfo.serviceState = !moduleInfo.serviceState;
  checkContent(commandObj.value.runMode)

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
        // getList();
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