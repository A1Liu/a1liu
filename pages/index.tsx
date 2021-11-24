import { NextPage } from 'next';
import Head from 'next/head';
import Image from 'next/image';
import styles from './Home.module.css';
import Layout from '../components/Layout';

const Home: NextPage = () => {
  return (
    <Layout>
        Hello World!
    </Layout>
  );
};

export default Home;
