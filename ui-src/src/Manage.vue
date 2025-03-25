<template>
  <div style="height: 0.1rem;"></div>
  <van-nav-bar :left-text="t('common.back')" title="Zerotier For KSU" left-arrow @click-left="onClickLeft"
    safe-area-inset-top fixed  v-if="show"/>
  <!-- <van-empty :description="t('network.api-not-found')" v-if="show" /> -->
  <iframe :src="url" style="min-height: 82vh;min-width: 95vw;" frameborder="no" border="0"
      marginwidth="1" marginheight="1" scrolling="yes" allowtransparency="yes"></iframe>
  <div style="height: 2.8rem;"></div>
</template>

<script setup>
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
    show.value=true;
  }else{
    urlStart+="auth"
    show.value=false;
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
const onClickLeft=()=>{
  router.push('/')
}
init()
</script>