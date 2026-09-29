-- =========================================
-- 정책자금 관리 시스템 논리 데이터 모델
-- PostgreSQL DDL
-- =========================================

-- =========================
-- 1. 조직 / 운영
-- =========================

CREATE TABLE 정부 (
    정부코드 VARCHAR(20) PRIMARY KEY,
    정부명 VARCHAR(100) NOT NULL
);

CREATE TABLE 부처_마스터 (
    부처코드 VARCHAR(20) PRIMARY KEY,
    정부코드 VARCHAR(20) NOT NULL,
    부처명 VARCHAR(100) NOT NULL,

    CONSTRAINT fk_부처_정부
        FOREIGN KEY (정부코드)
        REFERENCES 정부(정부코드)
);

CREATE TABLE 수행기관 (
    기관코드 VARCHAR(20) PRIMARY KEY,
    부처코드 VARCHAR(20) NOT NULL,
    기관명 VARCHAR(100) NOT NULL,
    주소 VARCHAR(255),
    기관연락처 VARCHAR(30),

    CONSTRAINT fk_기관_부처
        FOREIGN KEY (부처코드)
        REFERENCES 부처_마스터(부처코드)
);

CREATE TABLE 담당부서 (
    부서코드 VARCHAR(20) PRIMARY KEY,
    기관코드 VARCHAR(20) NOT NULL,
    부서명 VARCHAR(100) NOT NULL,
    업무분장 TEXT,

    CONSTRAINT fk_부서_기관
        FOREIGN KEY (기관코드)
        REFERENCES 수행기관(기관코드)
);

CREATE TABLE 담당자 (
    사번 VARCHAR(20) PRIMARY KEY,
    부서코드 VARCHAR(20) NOT NULL,
    이름 VARCHAR(50) NOT NULL,
    직급 VARCHAR(50),
    이메일 VARCHAR(100),
    휴대전화 VARCHAR(20),
    재직상태 VARCHAR(20) NOT NULL
        CHECK (재직상태 IN ('재직', '휴직', '퇴사')),

    CONSTRAINT fk_담당자_부서
        FOREIGN KEY (부서코드)
        REFERENCES 담당부서(부서코드)
);

CREATE TABLE 담당자_발령이력 (
    이력일련번호 SERIAL PRIMARY KEY,
    사번 VARCHAR(20) NOT NULL,
    부서코드 VARCHAR(20) NOT NULL,
    시작일자 DATE NOT NULL,
    종료일자 DATE,

    CONSTRAINT fk_발령_담당자
        FOREIGN KEY (사번)
        REFERENCES 담당자(사번),

    CONSTRAINT fk_발령_부서
        FOREIGN KEY (부서코드)
        REFERENCES 담당부서(부서코드)
);

CREATE TABLE 연도별_부처예산 (
    부처예산일련번호 SERIAL PRIMARY KEY,
    부처코드 VARCHAR(20) NOT NULL,
    사업년도 INT NOT NULL,
    배정예산총액 NUMERIC(18,2) NOT NULL,

    CONSTRAINT fk_예산_부처
        FOREIGN KEY (부처코드)
        REFERENCES 부처_마스터(부처코드)
);

-- =========================
-- 2. 자금 / 공고
-- =========================

CREATE TABLE 정책자금_마스터 (
    자금코드 VARCHAR(20) PRIMARY KEY,
    자금명 VARCHAR(100) NOT NULL,
    자금용도 VARCHAR(100),
    우대금리대상여부 CHAR(1)
        CHECK (우대금리대상여부 IN ('Y', 'N'))
);

CREATE TABLE 연도별_정책자금 (
    연도별자금일련번호 SERIAL PRIMARY KEY,
    자금코드 VARCHAR(20) NOT NULL,
    기관코드 VARCHAR(20) NOT NULL,
    사업년도 INT NOT NULL,
    총예산규모 NUMERIC(18,2),
    기준금리 NUMERIC(5,2),

    CONSTRAINT fk_연도자금_자금
        FOREIGN KEY (자금코드)
        REFERENCES 정책자금_마스터(자금코드),

    CONSTRAINT fk_연도자금_기관
        FOREIGN KEY (기관코드)
        REFERENCES 수행기관(기관코드)
);

CREATE TABLE 공고 (
    공고번호 SERIAL PRIMARY KEY,
    연도별자금일련번호 INT NOT NULL,
    공고명 VARCHAR(200) NOT NULL,
    접수시작일 DATE NOT NULL,
    접수종료일 DATE NOT NULL,
    공고상태 VARCHAR(20)
        CHECK (공고상태 IN ('예정', '진행중', '마감')),

    CONSTRAINT fk_공고_연도자금
        FOREIGN KEY (연도별자금일련번호)
        REFERENCES 연도별_정책자금(연도별자금일련번호)
);

-- =========================
-- 3. 신청 / 심사
-- =========================

CREATE TABLE 기업_마스터 (
    사업자등록번호 VARCHAR(20) PRIMARY KEY,
    기업명 VARCHAR(100) NOT NULL,
    업종코드 VARCHAR(20),
    설립일자 DATE,
    기업형태 VARCHAR(30),
    소재지 VARCHAR(255)
);

CREATE TABLE 연도별_기업정보 (
    기업이력일련번호 SERIAL PRIMARY KEY,
    사업자등록번호 VARCHAR(20) NOT NULL,
    평가년도 INT NOT NULL,
    근로자수 INT,
    매출액 NUMERIC(18,2),
    우대사업 VARCHAR(100),
    우대기업 VARCHAR(100),
    성장단계 VARCHAR(50),

    CONSTRAINT fk_기업이력_기업
        FOREIGN KEY (사업자등록번호)
        REFERENCES 기업_마스터(사업자등록번호)
);

CREATE TABLE 기업_대표자 (
    대표일련번호 SERIAL PRIMARY KEY,
    사업자등록번호 VARCHAR(20) NOT NULL,
    성명 VARCHAR(50) NOT NULL,
    생년월일 DATE,
    대표권유형 VARCHAR(20),
    취임일자 DATE,
    대표연락처 VARCHAR(30),

    CONSTRAINT fk_대표자_기업
        FOREIGN KEY (사업자등록번호)
        REFERENCES 기업_마스터(사업자등록번호)
);

CREATE TABLE 기업_계좌_마스터 (
    계좌일련번호 SERIAL PRIMARY KEY,
    사업자번호 VARCHAR(20) NOT NULL,
    은행코드 VARCHAR(20),
    계좌번호 VARCHAR(50) NOT NULL,
    예금주명 VARCHAR(100),
    용도구분 VARCHAR(20)
        CHECK (용도구분 IN ('지급용', '상환용')),
    계좌상태 CHAR(1)
        CHECK (계좌상태 IN ('Y', 'N')),
    인증여부 CHAR(1)
        CHECK (인증여부 IN ('Y', 'N')),

    CONSTRAINT fk_계좌_기업
        FOREIGN KEY (사업자번호)
        REFERENCES 기업_마스터(사업자등록번호)
);

CREATE TABLE 지원신청 (
    신청번호 SERIAL PRIMARY KEY,
    기업이력일련번호 INT NOT NULL,
    공고번호 INT NOT NULL,
    담당자사번 VARCHAR(20) NOT NULL,
    신청일자 DATE NOT NULL,
    희망금액 NUMERIC(18,2),
    심사상태 VARCHAR(20)
        CHECK (심사상태 IN ('접수', '심사중', '승인', '반려')),

    CONSTRAINT fk_신청_기업이력
        FOREIGN KEY (기업이력일련번호)
        REFERENCES 연도별_기업정보(기업이력일련번호),

    CONSTRAINT fk_신청_공고
        FOREIGN KEY (공고번호)
        REFERENCES 공고(공고번호),

    CONSTRAINT fk_신청_담당자
        FOREIGN KEY (담당자사번)
        REFERENCES 담당자(사번)
);

CREATE TABLE 제출서류_종류_마스터 (
    서류종류코드 VARCHAR(20) PRIMARY KEY,
    서류명 VARCHAR(100) NOT NULL,
    필수여부 CHAR(1)
        CHECK (필수여부 IN ('Y', 'N'))
);

CREATE TABLE 제출서류_파일 (
    파일일련번호 SERIAL PRIMARY KEY,
    서류종류코드 VARCHAR(20) NOT NULL,
    확장자 VARCHAR(20),
    용량 BIGINT,
    업로드일시 TIMESTAMP,

    CONSTRAINT fk_파일_서류종류
        FOREIGN KEY (서류종류코드)
        REFERENCES 제출서류_종류_마스터(서류종류코드)
);

CREATE TABLE 신청_서류매핑 (
    매핑일련번호 SERIAL PRIMARY KEY,
    파일일련번호 INT NOT NULL,
    신청번호 INT NOT NULL,

    CONSTRAINT fk_매핑_파일
        FOREIGN KEY (파일일련번호)
        REFERENCES 제출서류_파일(파일일련번호),

    CONSTRAINT fk_매핑_신청
        FOREIGN KEY (신청번호)
        REFERENCES 지원신청(신청번호)
);

-- =========================
-- 4. 계약 / 집행
-- =========================

CREATE TABLE 약정 (
    약정번호 SERIAL PRIMARY KEY,
    신청번호 INT NOT NULL,
    지급계좌일련번호 INT NOT NULL,
    상환계좌일련번호 INT NOT NULL,
    체결일자 DATE NOT NULL,
    확정금액 NUMERIC(18,2),
    적용금리 NUMERIC(5,2),
    만기일자 DATE,
    대출유형 VARCHAR(20)
        CHECK (대출유형 IN ('직접대출', '대리대출')),
    약정상태 VARCHAR(20)
        CHECK (약정상태 IN ('정상', '해지', '환재', '사고')),

    CONSTRAINT fk_약정_신청
        FOREIGN KEY (신청번호)
        REFERENCES 지원신청(신청번호),

    CONSTRAINT fk_약정_지급계좌
        FOREIGN KEY (지급계좌일련번호)
        REFERENCES 기업_계좌_마스터(계좌일련번호),

    CONSTRAINT fk_약정_상환계좌
        FOREIGN KEY (상환계좌일련번호)
        REFERENCES 기업_계좌_마스터(계좌일련번호)
);

CREATE TABLE 금리변동이력 (
    금리이력일련번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    적용시작일 DATE NOT NULL,
    적용종료일 DATE,
    적용금리 NUMERIC(5,2),
    변경사유 VARCHAR(255),

    CONSTRAINT fk_금리이력_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호)
);

CREATE TABLE 담보물_마스터 (
    담보일련번호 SERIAL PRIMARY KEY,
    담보유형 VARCHAR(50),
    담보물정보 TEXT,
    소재지_식별번호 VARCHAR(100),
    담보가치 NUMERIC(18,2),
    담보상태 VARCHAR(20)
        CHECK (담보상태 IN ('가용', '해제', '멸실'))
);

CREATE TABLE 담보물_가치평가이력 (
    평가일련번호 SERIAL PRIMARY KEY,
    담보일련번호 INT NOT NULL,
    평가일자 DATE NOT NULL,
    평가가액 NUMERIC(18,2),
    평가기관 VARCHAR(100),
    비고 TEXT,

    CONSTRAINT fk_평가이력_담보
        FOREIGN KEY (담보일련번호)
        REFERENCES 담보물_마스터(담보일련번호)
);

CREATE TABLE 지급회차 (
    지급회차번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    회차 INT NOT NULL,
    지급방식 VARCHAR(20)
        CHECK (지급방식 IN ('일시지급', '분할지급')),
    지급예정일 DATE,
    지급예정금액 NUMERIC(18,2),
    지급상태 VARCHAR(20)
        CHECK (지급상태 IN ('예정', '완료', '취소')),
    지연사유 TEXT,

    CONSTRAINT fk_지급회차_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호)
);

CREATE TABLE 약정_담보_연결 (
    연결일련번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    담보일련번호 INT NOT NULL,
    담보설정금액 NUMERIC(18,2),
    설정순위 INT,

    CONSTRAINT fk_약정담보_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호),

    CONSTRAINT fk_약정담보_담보
        FOREIGN KEY (담보일련번호)
        REFERENCES 담보물_마스터(담보일련번호)
);

CREATE TABLE 지급회차_이력 (
    지급번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    회차 INT NOT NULL,
    지급예정일 DATE,
    실제지급일 DATE,
    실제지급금액 NUMERIC(18,2),
    처리결과 VARCHAR(20)
        CHECK (처리결과 IN ('성공', '실패', '보류')),

    CONSTRAINT fk_지급이력_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호)
);

-- =========================
-- 5. 상환관리
-- =========================

CREATE TABLE 상환계획 (
    계획번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    이전계획번호 INT,
    계획버전 INT,
    계획상태 VARCHAR(20)
        CHECK (계획상태 IN ('유효', '취소', '종료')),
    유효시작일 DATE,
    유효종료일 DATE,
    총상환예정액 NUMERIC(18,2),
    상환방식 VARCHAR(30)
        CHECK (상환방식 IN ('원리금균등상환', '만기일시상환')),

    CONSTRAINT fk_상환계획_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호),

    CONSTRAINT fk_상환계획_이전계획
        FOREIGN KEY (이전계획번호)
        REFERENCES 상환계획(계획번호)
);

CREATE TABLE 상환회차 (
    상환회차번호 SERIAL PRIMARY KEY,
    계획번호 INT NOT NULL,
    납부회차 INT NOT NULL,
    청구원금 NUMERIC(18,2),
    청구이자 NUMERIC(18,2),
    납부기한일 DATE,
    수납상태 VARCHAR(20)
        CHECK (수납상태 IN ('미납', '완납', '부분납')),

    CONSTRAINT fk_상환회차_계획
        FOREIGN KEY (계획번호)
        REFERENCES 상환계획(계획번호)
);

CREATE TABLE 연체 (
    연체일련번호 SERIAL PRIMARY KEY,
    상환회차번호 INT NOT NULL,
    연체발생일 DATE NOT NULL,
    연체해소일 DATE,
    연체상태 VARCHAR(20)
        CHECK (연체상태 IN ('진행', '해소됨')),
    연체원금 NUMERIC(18,2),
    연체가산이자 NUMERIC(18,2),
    연체단계 VARCHAR(30)
        CHECK (연체단계 IN ('1개월이내', '1~3개월', '3개월이상')),

    CONSTRAINT fk_연체_상환회차
        FOREIGN KEY (상환회차번호)
        REFERENCES 상환회차(상환회차번호)
);

CREATE TABLE 수납이력 (
    수납번호 SERIAL PRIMARY KEY,
    약정번호 INT NOT NULL,
    계좌일련번호 INT NOT NULL,
    실제납부일자 DATE,
    납부총액 NUMERIC(18,2),
    수납구분 VARCHAR(20)
        CHECK (수납구분 IN ('자동이체', '조기상환', '일반납부')),

    CONSTRAINT fk_수납_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호),

    CONSTRAINT fk_수납_계좌
        FOREIGN KEY (계좌일련번호)
        REFERENCES 기업_계좌_마스터(계좌일련번호)
);

CREATE TABLE 수납충당매핑 (
    충당번호 SERIAL PRIMARY KEY,
    수납번호 INT NOT NULL,
    약정번호 INT NOT NULL,
    상환회차번호 INT NOT NULL,
    수납구분 VARCHAR(20),
    충당원금 NUMERIC(18,2),
    충당이자 NUMERIC(18,2),
    충당연체료 NUMERIC(18,2),
    충당수수료 NUMERIC(18,2),

    CONSTRAINT fk_충당_수납
        FOREIGN KEY (수납번호)
        REFERENCES 수납이력(수납번호),

    CONSTRAINT fk_충당_약정
        FOREIGN KEY (약정번호)
        REFERENCES 약정(약정번호),

    CONSTRAINT fk_충당_상환회차
        FOREIGN KEY (상환회차번호)
        REFERENCES 상환회차(상환회차번호)
);
