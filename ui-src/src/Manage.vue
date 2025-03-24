<template>
  <div style="height: 0.1rem;"></div>
  <van-empty :description="t('network.api-not-found')" v-if="show" />
  <iframe :src="url" style="min-height: 82vh;min-width: 95vw;" frameborder="no" border="0"
      marginwidth="1" marginheight="1" scrolling="yes" allowtransparency="yes"></iframe>
  <div style="height: 2.8rem;"></div>
</template>

<script setup>
// import { ref } from 'vue';
// import { useRoute, useRouter } from 'vue-router'
import { MODDIR, execCmdWithCallback, execCmdWithErrno } from './tools'
import { useI18n } from './locales'; // 导入所有翻译信息
import { useModuleInfoStore } from './stores/status'


const { t } = useI18n();
const router = useRouter()
const route = useRoute()
const show = ref(false);
const url=ref('')
const moduleInfo = useModuleInfoStore();

const init = () => {
  // http://127.0.0.1:5566/index.html#/auth
  // http://127.0.0.1:5566/index.html#/config_generator
  // https://easytier.cn/web/index.html#auth
  // https://easytier.cn/web/index.html#config_generator
  console.info(route.params.param)
  let urlStart='';
  if(moduleInfo.privateDeployment){
    urlStart = 'http://127.0.0.1:5566/index.html#'
  }else{
    urlStart = 'https://easytier.cn/web/index.html#'
  }
  if(route.params.param == 'config'){
    urlStart+="/config_generator"
  }else{
    urlStart+="auth"
  }
  url.value = urlStart;
  // execCmdWithErrno(`sh ${MODDIR}/api.sh apiToken show`).then(v => {
  //   console.info(`v:${v}`)
  //   if (v == 0) {
  //     router.push('/manage/network')
  //   } else {
  //     show.value = true;
  //     // showDialog({ message: '未配置apiToken,先去设置页添加一个吧' });
  //   }
  // })

}
init()
const newAdd = (index) => {
  showConfirmDialog({
    message:
      t('network.ask_new_network'),
  }).then(() => {
    setTimeout(() => {
      execCmdWithCallback({
        cmd: `sh ${MODDIR}/api.sh central network add`, onSuccess: (data) => {
          showToast(t('network.operation_success'));
          window.location.reload();
        }, onError: (data) => {
          showToast(t('network.operation_fail') + data);
        }
      })
    }, 50);
  }).catch(() => {
    resolve(true);
  })
}
defineExpose({ newAdd });
</script>